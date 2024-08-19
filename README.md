
# Tea Leaves

A LSP server for [teal](https://github.com/teal-language/tl).

[![test](https://github.com/svermeulen/tea-leaves/actions/workflows/test.yml/badge.svg)](https://github.com/svermeulen/tea-leaves/actions/workflows/test.yml)

# Installation

### From luarocks

* `luarocks install tea-leaves`
* `tea-leaves`

### From source

* Clone repo
* From repo root:
  * `luarocks init`
  * `./luarocks make`
  * `./lua_modules/bin/tea-leaves`

# Usage

```
tea-leaves [--verbose=true] [--log-name-method=by_proj_path|by_date]
```

Note:

* All args are optional

