Logging
=======

**Logging** is a logging facility written in [CoffeeScript](http://coffeescript.org/) based on the famous [SLF4J framework](http://www.slf4j.org/) known from Java.


Usage
-----
Example usage in **CoffeeScript** (Javascript usage see below):

```coffeescript
Log = require 'Logging'

# Create new Log instance with the name my-log-name and default log level INFO
log = new Log 'my-log-name'

# Ordinary logging
log.info 'First log message'

log.debug 'Not displayed due to lower log level'

# Output all levels
log.level = Log.Level.ALL

log.debug 'This is now {} by {}', 'displayed', log.name
# Output: This is now displayed by my-log-name

log.debug 'Display arguments in any order: {1} and {0} and again {1}', 14, 36
# Output: Display arguments in any order: 36 and 14 and again 36

# Function is only executed if logging actually happens, should be used for expensive operations or any non-trivial arguments
log.debug -> JSON.stringify { foo: 'bar' }
# Output: {"foo":"bar"}

# Asynchronous logging after two seconds
log.debug (done) ->
    setTimeout ->
        done JSON.stringify { abc: 'xyz' }
    , 2000
# Output: {"abc":"xyz"}
```

Example usage in **Javascript**:

```javascript
var Log = require("Logging"),

	// Create new Log instance with the name my-log-name and default log level INFO
	log = new Log("my-log-name");

// Ordinary logging
log.info("First log message");

log.debug("Not displayed due to lower log level");

// Output all levels
log.level = Log.Level.ALL;

log.debug("This is now {} by {}", "displayed", log.name);
// Output: This is now displayed by my-log-name

log.debug("Display arguments in any order: {1} and {0} and again {1}", 14, 36);
// Output: Display arguments in any order: 36 and 14 and again 36

// Function is only executed if logging actually happens, should be used for expensive operations or any non-trivial arguments
log.debug(function() {
	return JSON.stringify({ foo: "bar" });
});
// Output: {"foo":"bar"}

// Asynchronous logging after two seconds
log.debug(function(done) {
	setTimeout(function() {
		done(JSON.stringify({ abc: "xyz" }));
	}, 2000);
});
// Output: {"abc":"xyz"}
```


Configuration
-------------
The auto-configuration looks for a file named **logconf.json** in the current or parent directories.

You can pass a custom file name or JSON config object to the *Log.init()* method **before** Log instances are created.

The JSON configuration has the following structure (all entries are optional):

```json
{
	"adapters": [
		{
			"type": "ConsoleAdapter",
			"min":  "DEBUG",
			"max":  "WARN"
		},
		{
			"type": "FileAdapter",
			"min":  "WARN",
			"max":  "FATAL",
			"file": "error.log",
			"opts": {
				"overwrite": true
			}
		}
	],
	
	"levels": {
		"": "INFO",
		"org.foo": "WARN",
		"my.app": "ALL",
		"my.app.sub-module": "INFO"
	}
}
```

With *levels[""]* you can set the default log level for all logs as fall-back.


Log constructor
-----------
`log = new Log(name, [level], [adapter])`

* **name** The required logger name used for the output line
* *level* Optionally initialize this logger to the given level instead of *Log.DEFAULT_LEVEL* (defaults to *Log.Level.INFO*)
* *adapter* Optionally use adapter for this logger instead of *Log.DEFAULT_ADAPTER* (defaults to *ConsoleAdapter*)


Log levels
----------
The following log levels exist sorted by level importance (highest first):

* Log.Level.FATAL
* Log.Level.ERROR
* Log.Level.WARN
* Log.Level.INFO
* Log.Level.DEBUG
* Log.Level.TRACE

There is also *Log.Level.ALL* which will log for all log levels and *Log.Level.OFF* which completely suppresses logging.


Adapters
--------
You can pass any adapter you like into the Log constructor as third argument.

### ConsoleAdapter
This **default adapter** will make use of the [Console API](https://getfirebug.com/wiki/index.php/Console_API) usually available for common environments.

It will log the messages to the *console* object supporting its methods for different log levels.

### FileAdapter
A FileAdapter is created by `new FileAdapter(filepath, options)`.

The optional *options* are:
* **nocache**  
The default behavior is to open a file once to avoid write concurrency.
This options disables this behavior.

* **overwrite**  
Instead of appending to a file, overwrite it on opening.

* **openFlags**  
For more file opening control you can pass the exact open flags with this option.

* **mode**  
The file open mode, defaults to 0644.

### TeeAdapter
Usage: `adapter = new TeeAdapter(adapter1, adapter2, ...)`

This is a pseudo adapter which just passes the adapter calls to all adapters given in the constructor.
