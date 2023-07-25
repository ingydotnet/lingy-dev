Lingy
=====

A Clojure Platform for Perl


# Synopsis

Run the Lingy REPL:

```
$ lingy
Lingy 0.1.12 [perl]

user=> (p<TAB>
pos?     println  prn      pr-str
user=> (prn "Hello, world!")
"Hello, world!"
nil
user=>
```

or a Lingy one-liner:

```
$ lingy -e '(println "Hello, world!")'
Hello, world!
```

or run a Lingy program file:

```
$ echo '(println "Hello, world!")' > hello.ly
$ lingy hello.ly
Hello, world!
```

or run an example Lingy program:

```
$ wget -q https://raw.githubusercontent.com/ingydotnet/lingy/main/eg/99-bottles.ly
```

```
$ cat 99-bottles.ly
(defn main [number]
  (let [
    paragraphs (map paragraph (range number 0 -1)) ]
    (map println paragraphs)))

(defn paragraph [num]
  (str
    (bottles num) " of beer on the wall,\n"
    (bottles num) " of beer.\n"
    "Take one down, pass it around.\n"
    (bottles (dec num)) " of beer on the wall.\n"))

(defn bottles [n]
  (cond
    (= n 0) "No more bottles"
    (= n 1) "1 bottle"
    :else (str n " bottles")))

(main (nth *command-line-args* 0 99))
```

```
$ lingy 99-bottles.ly 3
3 bottles of beer on the wall,
3 bottles of beer.
Take one down, pass it around.
2 bottles of beer on the wall.

2 bottles of beer on the wall,
2 bottles of beer.
Take one down, pass it around.
1 bottle of beer on the wall.

1 bottle of beer on the wall,
1 bottle of beer.
Take one down, pass it around.
No more bottles of beer on the wall.
```


# Status

Lingy is in ALPHA status.


# Description

Lingy is an implementation of the Clojure Platform for Perl that is written in
Perl and hosted by Perl.
Programs and modules written in Lingy have full access to Perl and its CPAN
modules.

Perl modules can be written in Lingy and distributed on CPAN.
(In the future) Lingy code is compiled to a bytecode and should perform on the
same order of magnitude as XS modules.

Since Lingy will be a complete Clojure implementation, it should be able to run
programs written in Clojure and make use of libraries written in Clojure.

Clojure is a language that cleanly solves many of the problems of Java
including making concurrency simple, and writing functional programs with
mostly immutable data types.
It is a Lisp dialect that is hosted by Java and compiles to JVM byte code.
It has access to any libraries that target the JVM.

Much of the Clojure language is written in Clojure (self hosted) and Lingy
actually uses the Clojure source code.

A variant of Clojure called ClojureScript uses the same Clojure source code but
is hosted by JavaScript with full access to NPM modules.
Lingy also intends to eventually be ported to and hosted by many other
programming languages.

Lingy started as a Perl [implementation](
https://github.com/ingydotnet/mal/tree/perl.2/impls/perl.2) of the
[Make a Lisp](https://github.com/kanaka/mal) project.
This provided a bare-bones Clojure-inspired Lisp interpreter from which Lingy
has grown upon.


# Installation

The current implementation of Lingy is packaged for installation as a
[Perl module distribution package on CPAN](
https://metacpan.org/pod/Lingy).
This is obvious if you are reading this from CPAN now, but maybe not if you are
reading this from the [GitHub repository](
https://github.com/ingydotnet/lingy).

The easiest way to install Lingy is using the `cpanm` Perl/CPAN installation
tool:

```
cpanm Lingy
```

The `cpanm` command is available as a software install on most modern systems,
but if you are having trouble finding it see these [simple instructions](
https://metacpan.org/pod/App::cpanminus#INSTALLATION).

**NOTE**: See "Hacking on Lingy" below if you want to install from source
and/or hack on the Lingy source code yourself (and hopefully contribute to the
project!).


# `lingy` CLI Usage

The Lingy language installs a command-line program called `lingy`.
You can use this command to run Lingy programs, start a Lingy REPL or run
Lingy one-liner expressions.

* `lingy --repl` (or just `lingy`)

  Starts a Lingy interactive REPL.
  The REPL has readline support that includes:

  * Command history
  * CTL-R searching
  * Parentheses match highlighting
  * CTL-C to abort a command w/o leaving REPL

  Use CTL-D to exit the REPL

* `lingy program.ly foo bar`

  Run a Lingy program passing in arguments.
  Arguments are available in Lingy as `*command-line-args*`.

* `cat program.ly | lingy - foo bar`

  Run a Lingy program from STDIN and pass in arguments.
  The `-` means run from STDIN instead of a file.
  If there are no arguments you can omit the `-`.

* `lingy -e '(println "Hello" (first *command-line-args*))' world`

  Run a Lingy one-liner with arguments.

  When used with `--repl`, run the `-e` code first, then enter the REPL.


## `lingy` CLI Options

* `-e <string>`, `--eval=<string>`

  A Lingy string to evaluate.

* `-r`, `--repl`

  Start a Lingy REPL.
  Can be used with `-e`.

* `--ppp`

  Print the Lingy compiled AST for a `-e` expression.

* `--xxx`

  YAML dump the Lingy compiled AST for a `-e` expression.

* `--nrepl`

  Start a Lingy nREPL server for use by external REPLs and editors/IDEs, like
  [leiningen](https://leiningen.org/) and [Calva](https://calva.io/).


# Lingy REPL Usage

If you run `lingy --repl` (or just `lingy`) you will start a Lingy interactive
REPL.
You can run Lingy commands and see the output.

The REPL has command line history to save all your commands.
It also has readline history search (ctl-r) and tab completion.

Note: Input lines that match the previous input line will not be saved in
history.
That way you can run the same command multiple times in a row and not clutter
your history.


## Multiline Input

The Lingy REPL will keep prompting you for more lines until you have completed
a well formed expression.
Usually that means until you have balanced the parentheses.

The history (up adn down arrow keys) will bring up the entire multiline form
for you to edit.

If you want to enter multiple lines as one entry when each line is already
well formed, just wrap the entry in a `do` expression like so:

```
user=> (do
  #_=> (prn 1)
  #_=> (prn 2)
  #_=> )
1
2
nil
```

You can also paste multiline examples into the REPL and they will remain
editable as multiline.

If you want to compress a multiline statement in your history to a single
line, add a space to the end of it.
Then (after you run it) it will be added to your history as a single line.


## Using the Clojure REPL in the Lingy REPL

If you have Clojure installed on your system and you run this command in the
Lingy REPL: `(clojure-repl-on)`, then every command you enter will be evaluated
both by Lingy and Clojure.
Run `(clojure-repl-off)` to turn it off.
Start the Lingy REPL with `lingy --clj` to turn it on from the start.

Also if you run a command like `;;;(source first)` it will only run on Clojure.
The command is a comment to Lingy but the REPL will remove the `;;;` and pass
it to Clojure.

Using this feature is a great way to compare how Lingy and Clojure work.
Eventually they should be very close to identical but currently Lingy is still
a baby.


## nREPL Support

To use Clojure editors/IDEs with Lingy, you can start the REPL with nREPL
support.

To start a Lingy nREPL server for a project, run `lingy --nrepl` in the project
directory.
The server will write its port number to the standard `.nrepl-port` file and
its PID number to `.nrepl-port`.

You can enable nREPL logging (in YAML format) by setting the `LINGY_NREPL_LOG`
environment variable.
The variable's value can be the name/path of the log file to be created or `-`
to write to stdout.
Setting the value to `1` will write to `.nrepl-log`.

Note: This is a new feature and is still buggy. It works pretty good with Calva
but currently fails to connect with `lein repl :connect`.


# Lingy / Perl Interoperability

Like Clojure and Java, Lingy and Perl are both ways interoperable.

Note: This section currently covers the basics, but more in depth content will
be added later.


## Using Lingy from Perl Code

The Lingy.pm module lets you easily evaluate Lingy code from inside your Perl
code.

```
use Lingy;
my $lingy = Lingy->new;     # Setup the Lingy environment
my $result = $lingy->rep("(+ 1 2 3 4)");
```

### Lingy Methods

The Lingy perl module supports the following methods:

* `my $lingy = Lingy->new();`

  Create a new Lingy object.

  This method takes no arguments.

  The first time `Lingy->new` is called it initializes the Lingy runtime
  environment (which is required to process Lingy expressions).

* `my $result_string = $lingy->rep($lingy_source_code_string);`

  The `rep` method stands for `Read`, `Evaluate`, `Print` which is the runtime
  process for running Lingy (or any Lisp) code.
  This is likely the most common method you will use.

  Note: If you call this in a "Loop" you've created a "REPL" (Read, Evaluate,
  Print, Loop).

Lingy also exposes each of the Read, Evaluate and Print methods to give you
more control:

* `my $form = $lingy->read($lingy_source_code_string);`

  Read a string containing a Lingy source expression and return the Lingy AST
  object (form).
  In list context, returns all the form objects read if more than one form is
  parsed.

* `my $result_form = $lingy->eval($form);`

  Evaluate a Lingy form object and return the resulting Lingy form object.

  Use this in a Perl `eval` block to catch any Lingy runtime errors.

* `my $result_string = $lingy->print($form);`

  Print a Lingy form object to a text string.

  Usually this results in a Lingy expression that you can pass to another
  `$lingy->read` method call if you want to.

  Reading and Printing a Lingy string without Evaluating it in between, often
  produces the original string (or a semantically equivalent one).
  That's because Lisp (Lingy) is "homoiconic".


## Using Perl from Lingy Code

Like Clojure, Lingy has a lot of functions/functionality for calling Perl code.

This is how Clojure and Lingy are implemented in that as much of the language
as possible is written in itself (Lisp) but many functions need to call to the
host language to do the work.

* `(perl "any perl source code string")`

  This is the big hammer.
  Call Perl's `eval` on any Perl code string and return the result.

  The return value likely will not be a Lingy native object.
  If you save the result in a variable, don't expect that if will work like a
  native Lingy object.
  When the Lingy Printer sees a non-Lingy object it prints it as a YAML dump.

* `(import YAML.PP.Perl)`

  Load a Perl module.
  We are just using `YAML::PP::Perl` as an example here.
  This is like `use YAML::PP::Perl;` in Perl.

* `(def y-pp (YAML.PP.Perl. "boolean" "JSON::PP"))`

  Create a new `YAML::PP::Perl` object.
  The `.` after the module name is like calling the `->new` in Perl.

* `(def y-pp (.new YAML.PP.Perl "boolean" "JSON::PP"))`

  Call a Perl class method with arguments.
  This is another way to instantiate an object like the previous example.
  The `.xyz word at the start of an expression is like calling `->xyz` on the
  second word, which may be a class or an object.

* `(println (.dump ypp '(+ 2 2)))`

  Call a Perl method with arguments on a Perl instance object.

  The example above will print the internal AST form of the Lingy expression
  `(+ 2 2)`.
  This is a very useful way to debug Lingy.

* `WWW`, `XXX`, `YYY` and `ZZZ`

  These Lingy functions from the `lingy.devel` library, work like the `XXX.pm`
  CPAN module, but from Lingy.

  This can we very useful for seeing what Lingy is doing internally.

  ```
  (use 'lingy.devel) (XXX (perl "\\%INC"))  ; Print a YAML dump of Perl's %INC value.
  ```


# Differences from Clojure

Lingy intends to be a proper "Clojure Platform"; a complete port of Clojure to
Perl and other languages.

That said, differences must exist.

* The Lingy platform host language is currently just Perl.
  It is the intent to extend the language set to Python and others soon.
* Lingy currently only supports a subset of Clojure libraries (most notably
  clojure.core).
  It is intended that Lingy will eventually use Clojure's libraries directly
  starting with clojure.core.
  As of this release Lingy can `read-string` all of clojure.core and it
  converts the forms it fully supports into the lingy.core namespace.
* Lingy tries to map Clojure namespace and Java class symbols/files to Lingy
  namespace and Perl module/class symbols/files.
  * The `clojure.core` namespace equivalent in Lingy is `lingy.core` and maps
    to a file name called `lib/Lingy/core.ly` in the Lingy source code.
  * The `lingy.lang.HashMap` symbol maps to the `Lingy::HashMap` module (the
    `lib/Lingy/HashMap.pm` file).
  * More mapping details to be added here later.
* The `#?` reader macro uses the `:lingy/pl` keyword to conditionally use forms
  that the Lingy/Perl platform supports.
* Special global vars (earmuffs) that are unique to Lingy:
  * `*lingy-version*`
    Like `*clojure-version*` but for Lingy's version.
  * `*LANG*`
    Set to `"Lingy"`.
  * `*HOST*`
    Set to `"perl"`.
  * `*clojure-repl*`
    Boolean (default `false`) indicates whether Lingy REPL should also send
    input to a Clojure REPL.
* Lingy error messages currently try to be close to the Clojure ones.
  * This isn't always possible or desirable.
  * Error messages may be completely overhauled to give better info.

Certainly there are other differences and this section will be improved over
time.


# Hacking on Lingy

If you want to contribute to Lingy, Welcome!

If you just want to play with the source while using Lingy, Welcome!

Here, we'll cover how to install Lingy from source and modify the source code.
This will include tips on debugging Lingy.

This section is a work in progress...

Lingy development requires `git`, `bash`, `perl`, `make`, `curl` (almost any
versions of these) and a bunch of Perl modules.

You probably already have the commands.
The best way to install the dependency modules is using the `cpanm Lingy`
command described above in the "Installation" section.
The will install Lingy and all the Perl dependencies.

Then you can `git clone` the source code:
```
git clone https://github.com/ingydotnet/lingy.git
```

Set up local environment variables for development:
```
export PATH=$PWD/lingy/perl/bin:$PATH
export PERL5LIB=$PWD/lingy/perl/lib
```

And test your local source code install of Lingy:
```
which lingy     # Should point at your cloned version
lingy --execs   # Should list your clone
lingy -e '(println *lingy-version*)'
```

Add the `export`s above to your shell rc file if you want to.

You might need to add these exports if Lingy warns about them.
This is more common for people who haven't used Perl in a while since people
who do likely took care of it in the past.
```
LC_CTYPE=en_US.UTF-8
LC_ALL=en_US.UTF-8
```


## Debugging Lingy in the REPL

Running `lingy -D` will `(use 'lingy.devel)` at startup.
This provides some dev functions including:

* `(XXX ...)`

  Throw a YAML dump of the internal Perl structure of the arguments.

* `(WWW ...)`

  Warn the same thing as above but then return the argument so that the program
  can continue.

* `(x-carp-on)`

  Turn on full stack traces when Perl internally warns or dies.
  Calling `(throw ...)` should also get a full stack trace with this.

* A bunch of other functions starting with `x-`.
  Tab completion is your friend. :)


# See Also

* [Video Talk about Lingy and YAMLScript](https://www.youtube.com/watch?v=9OcFh-HaCyI)
* [Clojure](https://clojure.org/)
* [YAMLScript](https://metacpan.org/pod/YAMLScript)
* [Test::More::YAMLScript](https://metacpan.org/pod/Test::More::YAMLScript)


# Authors

* [Ingy döt Net](https://github.com/ingydotnet)
* [Peter Strömberg](https://github.com/PEZ)


# Copyright and License

Copyright 2023 by Ingy döt Net

This is free software, licensed under:

The MIT (X11) License
