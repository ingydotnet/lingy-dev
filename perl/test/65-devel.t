use Lingy::Test;

use lib './test/lib';

tests <<'...';
- [ (use 'lingy.devel), nil ]

- note: XXX Regression
# - [ (resolve 'WWW), "#'lingy.devel/WWW" ]

- - (WWW (x-class-names))
  - /- Lingy::Atom/
- - (WWW (x-core-ns))
  - >-
      /cons: .*!perl/code '\{ "DUMMY" }'/
...
