Logging
=======

**Logging** is a logging facility written in [CoffeeScript](http://coffeescript.org/) based on the famous [SLF4J framework](http://www.slf4j.org/) known from Java.

Usage
-----

```coffeescript
Log = require 'Log'

# Create new Log instance with the name my-log-name and default log level INFO
log = new Log 'my-log-name'

# Ordinary logging
log.info 'First log message'

log.debug 'Not displayed due to lower log level'

# Output all levels
log.level = Log.Level.ALL

log.debug 'This is now {} by {}', 'displayed', log.name           # Output: This is now displayed by my-log-name

log.debug 'Display arguments in any order: {1} and {0}', 14, 36   # Output: Display arguments in any order: 36 and 14

log.debug -> JSON.stringify { foo: 'bar' }                        # Function is only executed if logging actually happens, can be used for expensive operations
                                                                  # Output: {"foo":"bar"}

log.debug (done) ->                                               # Asynchronous logging after two seconds
    setTimeout ->                                                 # Output: {"abc":"xyz"}
        done(JSON.stringify { abc: 'xyz' })
    , 2000
```

Adapters
--------
At the moment there is just one adapter for the log message to process: the *ConsoleAdapter*

It uses the console object provided by the [Console API](https://getfirebug.com/wiki/index.php/Console_API).

You can pass any adapter you like into the Log constructor as third argument.

Constructor
-----------
log = new Log(**name**, [*level*], [*adapter*])

Using **Logging** in Javascript
-------------------------------
You can compile the CoffeeScript into Javascript by installing the [CoffeeScript compiler](http://coffeescript.org/) and executing:
```bash
coffee --compile --output js src/
```

After that you can use **Logging** just like any other Javascript CommonJS module with the methods shown above.
