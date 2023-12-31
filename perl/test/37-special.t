use Lingy::Test;

tests <<"...";
- - (special-symbol? 'xyz)
  - 'false'
- - (special-symbol? 'def)
  - 'true'
- - (special-symbol? 'loop*)
  - 'true'
- - (resolve 'loop*)            # XXX
  - nil
- - (special-symbol? 'recur)
  - 'true'
- - (special-symbol? 'if)
  - 'true'
- - (special-symbol? 'let*)
  - 'true'
- - (special-symbol? 'do)
  - 'true'
- - (special-symbol? 'fn*)
  - 'true'
- - (special-symbol? 'quote)
  - 'true'
- - (special-symbol? 'var)
  - 'true'
- - (special-symbol? 'import*)
  - 'true'
- - (special-symbol? '.)
  - 'true'
- - (special-symbol? 'try)
  - 'true'
- - (special-symbol? 'throw)
  - 'true'
- - (special-symbol? 'catch)
  - 'true'
- - (special-symbol? 'new)
  - 'true'
...
