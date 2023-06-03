use strict; use warnings;
package Lingy::Lang::RT;

use Lingy;
use Lingy::Common;
use Lingy::Eval;
use Lingy::Lang::HashMap;
use Lingy::Lang::Namespace;
use Lingy::Lang::Nil;
use Lingy::Lang::Sequential;
use Lingy::Lang::Symbol;
use Lingy::ReadLine;

use constant LANG => 'Lingy';
use constant HOST => 'perl';

use constant env_class => 'Lingy::Env';
use constant printer_class => 'Lingy::Printer';
use constant reader_class => 'Lingy::Reader';

my @class_names = (
    ATOM,
    BOOLEAN,
    CHARACTER,
    CLASS,
    COMPILER,
    FUNCTION,
    HASHMAP,
    KEYWORD,
    LIST,
    LISTTYPE,
    MACRO,
    NIL,
    NUMBER,
    REGEX,
    SEQUENTIAL,
    STRING,
    SYMBOL,
    VAR,
    VECTOR,
    NUMBERS,
    RT,
    TERM,
    THREAD,
    UTIL,
);
sub class_names { \@class_names }

my $current_ns_name;
sub current_ns_name { $current_ns_name = $_[1] // $current_ns_name }

my %namespaces;
bless \%namespaces, 'lingy-internal';
sub namespaces { \%namespaces }
sub current_ns { $namespaces{$current_ns_name} }

my %ns_refers;
bless \%ns_refers, 'lingy-internal';
sub ns_refers { \%ns_refers }

my %classes;

my %meta;
sub meta { \%meta }

my $env;
sub env { $env }

my $reader;
sub reader { $reader }

my $printer;
sub printer { $printer }

my $core_ns;
sub core_ns { $core_ns }

my $user_ns;
sub user_ns { $user_ns }

my $ready = 0;
sub ready { $ready }

sub init {
    my ($self) = @_;

    for my $package_name (@class_names) {
        eval "require $package_name; 1" or die $@;
        my $class = CLASS->_new($package_name);
        my $class_name = $class->_name;
        $classes{$class_name} = $class;
        if ($class_name =~ /\.(\w+)$/) {
            $classes{$1} = $class;
        }
    }

    $env     = $self->require_new($self->env_class);
    $reader  = $self->require_new($self->reader_class);
    $printer = $self->require_new($self->printer_class);

    $core_ns = $self->core_namespace();
    $user_ns = $self->user_namespace();

    $user_ns->current;

    $ready = 1;

    return $self;
}

sub core_namespace {
    my ($self) = @_;

    my $ns = NAMESPACE->new(
        name => 'lingy.core',
        %classes,
    )->current;

    $ns->{$_} = $classes{$_} for keys %classes;

    my $argv = @ARGV
        ? LIST->new([
            map STRING->new($_), @ARGV[1..$#ARGV]]
        ) : NIL->new;

    # Define these functions first for bootstrapping:
    $env->set(cons => \&cons);
    $env->set(concat => \&concat);
    $env->set(eval => sub { evaluate($_[0], $env) });

    # Clojure dynamic vars:
    $env->set('*file*', STRING->new(
        $ARGV[0] || "NO_SOURCE_PATH"
    ));
    $env->set('*command-line-args*', $argv);

    # Lingy dynamic vars:
    $env->set('*ARGV*', $argv);
    $env->set('*LANG*', STRING->new($self->LANG));
    $env->set('*HOST*', STRING->new($self->HOST));

    $Lingy::VERSION =~ /^(\d+)\.(\d+)\.(\d+)$/;
    $self->rep("
      (def *lingy-version*
        {
          :major       $1
          :minor       $2
          :incremental $3
          :qualifier   nil
        })

      (def *clojure-version*
        {
          :major       1
          :minor       11
          :incremental 1
          :qualifier   nil
        })
    ");

    my $core_ly = $INC{'Lingy/Lang/RT.pm'};
    $core_ly =~ s/Lang\/RT\.pm$/core.ly/;
    $self->rep($self->slurp_file($core_ly));

    return $ns;
}

sub user_namespace {
    my ($self) = @_;

    NAMESPACE->new(
        name => 'user',
        refer => [
            $self->core_ns,
        ],
    );
}

sub require_new {
    my $self = shift;
    my $class = shift;
    eval "require $class; 1" or
        die "Can't require '$class':\n$@";
    $class->new(@_);
}

sub slurp_file {
    my ($self, $file) = @_;
    open my $slurp, '<', "$file" or
        die "Couldn't read file '$file'";
    local $/;
    <$slurp>;
}

sub rep {
    my ($self, $str) = @_;
    map $printer->pr_str(evaluate($_, $env)),
        $reader->read_str($str);
}

sub repl {
    my ($self) = @_;

    $self->rep(q< (println (str *LANG* " " (lingy-version) " [" *HOST* "]\n"))>)
        unless $ENV{LINGY_TEST};
    my ($clojure_repl) = $self->rep("(identity *clojure-repl*)");
    if ($clojure_repl eq 'true') {
        require Lingy::ClojureREPL;
        Lingy::ClojureREPL->start();
    }

    while (defined (my $line = Lingy::ReadLine::readline)) {
        next unless length $line;

        my @forms = eval { $reader->read_str($line, 1) };
        if ($@) {
            print "$@\n";
            $Lingy::ReadLine::input = '';
            next;
        }

        for my $form (@forms) {
            my $ret = eval {
                $printer->pr_str(evaluate($form, $env));
            };
            my $err;
            $err = $ret = $@ if $@;
            chomp $ret;
            print "$ret\n";
        }

        my $input = $Lingy::ReadLine::input // next;
        ($clojure_repl) = $self->rep("(identity *clojure-repl*)");

        if ($input =~ s/^;;;// or $clojure_repl eq 'true') {
            require Lingy::ClojureREPL;
            Lingy::ClojureREPL->rep($input);
        }
    }
    print "\n";
}


#------------------------------------------------------------------------------

sub all_ns {
    list([
        map { $namespaces{$_} }
        sort keys %namespaces
    ]);
}

sub apply {
    my ($fn, $args) = @_;
    my $seq = pop(@$args);
    $seq = list([]) if ref($seq) eq NIL;
    push @$args, @$seq;
    ref($fn) eq 'CODE'
        ? $fn->(@$args)
        : evaluate($fn->(@$args));
}

sub assoc {
    my ($map, $key, $val) = @_;
    $map->assoc($key, $val);
}

sub atom_ { ATOM->new($_[0]) }

sub booleanCast {
    my ($val) = @_;
    my $type = ref($val);
    $type eq NIL ? false :
    ($type eq BOOLEAN and $$val == 0) ? false :
    true;
}

sub charCast {
    my ($char) = @_;
    my $type = ref($char);
    err "Class '$type' cannot be cast to 'lingy.lang.Character'"
        unless $type eq SYMBOL or $type eq NUMBER;
    return CHARACTER->read($char);
}

sub concat { list([map @$_, @_]) }

sub conj {
    my ($o, @args) = @_;
    my $type = ref($o);
    $type eq LIST ? list([reverse(@args), @$o]) :
    $type eq VECTOR ? VECTOR->new([@$o, @args]) :
    $type eq NIL ? nil :
    throw("conj first arg type '$type' not allowed");
}

sub cons { list([$_[0], @{$_[1]}]) }

sub contains {
    my ($map, $key) = @_;
    return false unless ref($map) eq HASHMAP;
    $key =
        $key->isa(STRING) ? qq<"$key> :
        $key->isa(SYMBOL) ? qq<$key > :
        "$key";
    BOOLEAN->new(exists $map->{"$key"});
}

sub count {
    NUMBER->new(ref($_[0]) eq NIL ? 0 : scalar @{$_[0]});
}

sub create_ns {
    my ($name) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(\.\w+)*$/;
    NAMESPACE->new(
        name => $name,
        refer => $core_ns,
    );
}

sub dec { $_[0] - 1 }

sub deref { $_[0]->[0] }

sub dissoc {
    my ($map, @keys) = @_;
    @keys = map {
        $_->isa(STRING) ? qq<"$_> : "$_";
    } @keys;
    $map = { %$map };
    delete $map->{$_} for @keys;
    HASHMAP->new([%$map]);
}

sub find_ns {
    assert_args(\@_, SYMBOL);
    $namespaces{$_[0]} // nil;
}

sub first {
    ref($_[0]) eq NIL
        ? nil : @{$_[0]} ? $_[0]->[0] : nil;
}

sub get {
    my ($map, $key, $default) = @_;
    return nil unless ref($map) eq HASHMAP;
    $key = qq<"$key> if $key->isa(STRING);
    $map->{"$key"} // $default // nil;
}

sub getenv {
    my $val = $ENV{$_[0]};
    defined($val) ? string($val) : nil;
}

sub hash_map_ { HASHMAP->new([@_]) }

sub in_ns {
    my ($name) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(\.\w+)*$/;
    my $ns = $namespaces{$name} //
    NAMESPACE->new(
        name => $name,
    );
    $ns->current;
}

sub inc { $_[0] + 1 }

sub keys_ {
    list([
        map {
            s/^"// ? string($_) :
            s/^:// ? KEYWORD->new($_) :
            s/ $// ? symbol($_) :
            symbol("$_");
        } keys %{$_[0]}
    ]);
}

sub keyword_ { KEYWORD->new($_[0]) }

sub list_ { list([@_]) }

sub macroexpand {
    Lingy::Eval::macroexpand($_[0], $Lingy::Eval::ENV);
}

sub map {
    list([
        map apply($_[0], [$_, []]), @{$_[1]}
    ]);
}

sub meta_get {
    $meta{"$_[0]"} // nil;
}

sub name {
    string($_[0] =~ m{(.*?)/(.*)} ? $2 : "$_[0]");
}

sub namespace {
    $_[0] =~ m{(.*?)/(.*)} ? string($1) : nil;
}

my $nextID = 1000;
sub nextID {
    return $nextID = $_[1] if @_ == 2;
    string(++$nextID);
}

sub ns_ {
    my ($name, $args) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(\.\w+)*$/;

    my $ns;
    $ns = $namespaces{$name} //
    NAMESPACE->new(
        name => $name,
        refer => $core_ns,
    );
    $ns->current;

    for my $arg (@$args) {
        err "Invalid ns arg" unless
            $arg->isa(LIST) and
            @$arg >= 2 and
            ref($arg->[0]) eq KEYWORD;

        my ($keyword, @args) = @$arg;
        if ($$keyword eq ':use') {
            for my $spec (@args) {
                evaluate(
                    list([
                        symbol('use'),
                        list([symbol('quote'), $spec]),
                    ]),
                    $Lingy::Eval::ENV,
                );
            }
        }
        elsif ($$keyword eq ':import') {
            my (undef, @args) = @$arg;
            evaluate(
                list([ symbol('import'), @args ]),
                $Lingy::Eval::ENV,
            );
        }
        else {
            err "Invalid keyword arg '$keyword' in ns";
        }
    }

    nil;
}

sub nth { $_[0][$_[1]] }

sub number_ { NUMBER->new("$_[0]" + 0) }

sub pos_Q { $_[0] > 0 ? true : false }

sub pr_str {
    string(join ' ', map $printer->pr_str($_), @_);
}

sub println {
    printf "%s\n", join ' ',
        map $printer->pr_str($_, 1), @_;
    nil;
}

sub prn {
    printf "%s\n", join ' ',
    map $printer->pr_str($_), @_;
    nil;
}

sub quot { NUMBER->new(int($_[0] / $_[1])) }

sub read_string {
    my @forms = $reader->read_str($_[0]);
    return @forms ? $forms[0] : nil;
}

sub readline {
    require Lingy::ReadLine;
    my $l = Lingy::ReadLine::readline() // return;
    chomp $l;
    string($l);
}

sub refer_ {
    my (@specs) = @_;
    for my $spec (@specs) {
        err "'refer' only works with symbols"
            unless ref($spec) eq SYMBOL;
        my $refer_ns_name = $$spec;
        my $current_ns_name = $current_ns_name;
        my $refer_ns = $namespaces{$refer_ns_name}
            or err "No namespace: '$refer_ns_name'";
        my $refer_map = $ns_refers{$current_ns_name} //= {};
        map $refer_map->{$_} = $refer_ns_name,
            grep /^\S/, keys %$refer_ns;
    }
    return nil;
}

sub require {
    outer:
    for my $spec (@_) {
        err "'require' only works with symbols"
            unless ref($spec) eq SYMBOL;

        return nil if $namespaces{$$spec};

        my $name = $$spec;

        my $path = $name;
        $path =~ s/^lingy\.lang\./Lingy.Lang\./;
        $path =~ s/^lingy\./Lingy\./;
        my $module = $path;
        $path =~ s/\./\//g;

        for my $inc (@INC) {
            $inc =~ s{^([^/.])}{./$1};
            my $inc_path = "$inc/$path";
            if (-f "$inc_path.ly") {
                my $ns = $namespaces{$current_ns_name};
                RT->rep(qq< (load-file "$inc_path.ly") >);
                $ns->current;
                next outer;
            }
        }

        err "Can't find library for (require '$name)";
    }
    return nil;
}

sub reset_BANG { $_[0]->[0] = $_[1] }

sub resolve {
    my ($symbol) = @_;
    my ($ns_name, $sym_name, $var);
    if ($symbol =~ /(.*?)\/(.*)/) {
        ($ns_name, $sym_name) = ($1, $2);
    }
    else {
        $ns_name = $current_ns_name;
        $sym_name = $symbol;
    }

    my $ns = $namespaces{$ns_name} or return nil;
    if (exists $ns->{$sym_name}) {
        $var = $ns_name . '/' . $sym_name;
    } else {
        my $ref;
        if (($ref = $ns_refers{$ns_name}) and
            defined($ns_name = $ref->{$sym_name})
        ) {
            $var = $ns_name . '/' . $sym_name;
        } else {
            return nil;
        }
    }
    return VAR->new($var);
}

sub rest {
    my ($list) = @_;
    return list([]) if $list->isa(NIL) or not @$list;
    list([@{$list}[1..(@$list-1)]]);
}

sub seq {
    my ($o) = @_;
    $o->can('_to_seq') or
        err(sprintf "Don't know how to create ISeq from: %s", $o->NAME);
    $o->_to_seq;
}

sub slurp { string(RT->slurp_file($_[0])) }

sub sort {
    list([
        CORE::sort @{$_[0]}
    ]);
}

sub str {
    string(
        join '',
            map $printer->pr_str($_, 1),
            grep {ref($_) ne NIL}
            @_
    );
}

sub swap_BANG {
    my ($atom, $fn, $args) = @_;
    $atom->[0] = apply($fn, [[$atom->[0], @$args]]);
}

sub symbol_ { symbol("$_[0]") }

sub the_ns {
    $_[0]->isa(NAMESPACE) ? $_[0] :
    $_[0]->isa(SYMBOL) ? do {
        $namespaces{$_[0]} //
        err "No namespace: '$_[0]' found";
    } : err "Invalid argument for the-ns: '$_[0]'";
}

sub time_ms {
    require Time::HiRes;
    my ($s, $m) = Time::HiRes::gettimeofday();
    NUMBER->new($s * 1000 + $m / 1000);
}

sub type_ {
    CLASS->_new(ref($_[0]));
}

sub with_meta {
    my ($o, $m) = @_;
    $o = ref($o) eq 'CODE' ? sub { goto &$o } : $o->clone;
    $meta{$o} = $m;
    $o;
}

sub vals { list([ values %{$_[0]} ]) }

sub var_ { VAR->new($_[0]) }

sub vec { VECTOR->new([@{$_[0]}]) }

sub vector_ { VECTOR->new([@_]) }

1;
