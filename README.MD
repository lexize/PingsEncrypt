# Pings Encrypt
Library for [Figura](https://github.com/Kingdom-of-The-Moon/FiguraRewriteRewrite/) pings encryption.

Creates wrapper for builtin `pings`, so all pings you sending will be encrypted (if you want ofc).

## How to use
* Configure library.\
To start using library you have to configure it at first. Available settings:
  * `keys` - table with keys library will try to use for encryption/decryption.
  * `replace_pings` - Replace builtin pings variable or not? Must be set before library initialization (requiring).
  * `builtin_pings_variable` - Name of variable where builtin pings will be stored, if `replace_pings` is true. Default value - `"native_pings"`. Must be set before library initialization.
  * `encrypted_pings_variable` - Name of variable where pings wrapper will be stored, if `replace_pings` is false. Default value - `"encrypted_pings"`. Must be set before library initialization.
  * `default_key` - Default key library will use when sending ping, if ping was sent regular way, and not with `pings:sendWithKey()`. Set this value to `nil` to disable ping encryption without using `pings:sendWithKey()`. Default value - `"world"`.
* Create key(s).

    This can be done after requiring library, but this is still important part.

    Keys is basically just a tables with only one field - `secret`, ***that always have to be integer***.

    Library takes keys from settings, so this is standard key creation process:
    ```lua
    local settings = require("path.to.pings_encrypt.settings");
    local myKey = {
        secret = ... -- Your very hard to pick number 
    }
    settings.keys.your_key_name = myKey;
    ```
    Key can be also table with metatable, that generates key before getting. Can be easily created with `util.createFunctionKey(func)` where `util` is PingsEncrypt module, and `func` is function without arguments used for key generation. 
* Require library.\
Note: it ***must be*** required before you define any pings, otherwise you wont be able to call pings you defined before through this lib.
* Send pings!\
    Pings can be sent as with regular way, and also with `pings:sendWithKey(ping_name, key_name, ...args)`. Setting `key_name` to false will send ping without encryption.

### Contents:
* `pings.lua` - main script of library.
* `serializer.lua` - Script used to turn your ping arguments into byte script.\
    Functions:
    * `serialize(...args)` - serializes all arguments provided into one byte string.
    * `deserialize(byte_stream)` - reads byte stream and returns all values stored in it.
* `settings.lua` - Settings of library. Require to edit settings.
* `stream.lua` - Util class that makes it easier to read byte arrays.\
    Functions:
    * `createByteStream(...bytes)` - Creates byte stream of bytes provided to function.
* `util.lua` - Utils of library. You can check contents of it and see what's in it, but im gonna describe most useful functions:
    * `hashFromSource(...integers)` - Creates hash out of provided integer values. Returns 8 integers describing hash.
    * `createFunctionKey(func)` - Creates dynamic key that gets its value out of `func`.