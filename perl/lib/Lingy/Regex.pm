use strict; use warnings;
package Lingy::Regex;

use Lingy::Common;

# need these things:
# * if-some
# * "sequence destructuring bindings"

sub new {
    my ($class, $scalar) = @_;
    bless qr/$scalar/, $class;
}

sub find {
    return nil unless $_[1] =~ $_[0];
    return string($&) unless defined $1;
    my ($i, @capture) = (1, string($&));
    {
        no strict 'refs';
        while (defined (my $value = ${"$i"})) {
            push @capture, string($value);
            $i++;
        }
    }
    VECTOR->new([@capture]);
}

sub matches {
    find REGEX->new("\\A$_[0]\\z"), $_[1];
}

sub pattern {
    __PACKAGE__->new(@_);
}

1;
