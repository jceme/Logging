# Logging
**Logging** is a logging facility for *node.js* written in [CoffeeScript](http://coffeescript.org/) inspired by the famous [SLF4J framework](http://www.slf4j.org/) known from Java.


## Getting started
This logging framework can be used right away - without further configuration.

Example usage in **CoffeeScript** (Javascript usage see below):

```coffeescript
Log = require 'Logging'

# Create new Log instance.
log = new Log 'my.package.Module'

log.info 'This is a simple info log message'

log.debug 'This is a debug log message'
# Will not be displayed with default configuration

# Use log message parameters.
log.warn 'This is now {} by {}', 'displayed', log.name
## Output: This is now displayed by my.package.Module

log.error 'Display arguments in any order: {1} and {0} and again {1}', 14, 36
## Output: Display arguments in any order: 36 and 14 and again 36

# Function is only executed if this log level is really active.
# Should be used for expensive operations or any non-trivial arguments.
log.info -> JSON.stringify myLargeObject

# Asynchronous logging after two seconds
log.info (done) ->
    fn = -> done JSON.stringify myLargeObject
    setTimeout fn, 2000
```

Example usage in **Javascript**:

```javascript
var Log = require('Logging');

// Create new Log instance.
var log = new Log('my.package.Module');

log.info('This is a simple info log message');

log.debug('This is a debug log message');
// Will not be displayed with default configuration

// Use log message parameters.
log.warn('This is now {} by {}', 'displayed', log.name);
//// Output: This is now displayed by my.package.Module

log.error('Display arguments in any order: {1} and {0} and again {1}', 14, 36);
//// Output: Display arguments in any order: 36 and 14 and again 36

// Function is only executed if this log level is really active.
// Should be used for expensive operations or any non-trivial arguments.
log.info(function() {
    return JSON.stringify(myLargeObject);
});

// Asynchronous logging after two seconds
log.info(function(done) {
    setTimeout(function() {
        done(JSON.stringify(myLargeObject));
    }, 2000);
});
```


## Configuration
The auto-configuration will look for a file named `logconf.json` in the current and parent directories.
If found, this file will be used for configuring the logging. It uses a lax JSON format, including comment support.

Example `logconf.json` configuration:

```javascript
{
	loggers: [
		{
			type: "ConsoleLogger"             // Default type if omitted
			min:  "INFO"
		}
		
		{
			type: "FileLogger"
			filename: "error.log"
			overwrite: true
			min:  "WARN"
		}
		
		{
			type: "FileLogger"
			filename: "submodule-debug.log"
			
			// This replaces the global level config for this logger
			levels: {
				"": "OFF"                     // Suppress all other module output
				"my.app.submodule": "DEBUG"
			}
		}
	]
	
	basedir: "/var/log/mylogs"                // Will be used by all FileLoggers
	
	// Level config for all loggers
	levels: {
		"": "INFO",
		"org.foo": "WARN",
		"my.app": "ALL",
		"my.app.submodule": "INFO"
	}
}
```

The logging configuration consists of a global configuration (i.e. all items in the root object) and separate configurations for each output logger to create (i.e. each item in the `loggers` array).
Options are taken from the specific logger config if available, else from the global config or otherwise using the default values.

**Note** that level configuration is not merged but replaced!


### Log level configuration
The basic format for level configuration is an object for key `levels`, listing the packages with the minimum log level name.

Instead of the minimum level name, an array with the specific level names can be used, like `"my.app.foo": [ "DEBUG", "WARN" ]`

#### Log level names
Listing of all log level names in ascending order of importance:

| Level | Description |
| ----- | ----------- |
| TRACE | Low-level logging and tracing |
| DEBUG | Debug logging |
| INFO  | Informative logging |
| WARN  | Warnings which might affect system functionality |
| ERROR | Errors occurred in a system functionality |
| FATAL | Fatal errors occurred and the system is incapable of functioning |

There are two **special log levels**:
- `ALL` can be used to include all of the levels above
- `OFF` is suppressing logging for a package


#### Log level resolution
When creating a new Log instance like `var log = new Log("my.app.Module")` then the following resolution strategy for this instance is used:

1. Use level configuration for `"my.app.Module"` if available
2. Use level configuration for `"my.app"` if available
3. Use level configuration for `"my"` if available
4. Use level configuration for `""` if available (This configures the default log level)
5. Use the default level **INFO**


### Output logger options
| Logger | Option | Default value |
| ------ | ------ | ------------- |
| *General options* | levels | *see [above](#log-level-names)* |
|                   | formatPattern | *see [below](#log-message-format)* |
|                   | minLevel | INFO |
|                   | maxLevel | FATAL |
| ConsoleLogger | type | ConsoleLogger |
| FileLogger    | type | FileLogger *(required)* |
|               | filename | logging.log |
|               | basedir | . *(current directory)* |
|               | overwrite | false |
|               | mode | 0644 *(rw-r--r--)* |
|               | throwErrors | false |


The **ConsoleLogger** is the default ouput logger and make use of the [Console API](https://getfirebug.com/wiki/index.php/Console_API) which usually is available for common environments.
It will log the messages to the `console` object supporting its methods for different log levels.

For creating log files, the **FileLogger** can be used. It saves the log messages line-wise in a file.
By default, any IO-errors are silently ignored when logging, **NOT** when creating the FileLogger.
Use `throwErrors: true` to also throw errors when logging, but be aware that this could interfere with your code.


### Log message format
To configure the format of the log messages, use the key `formatPattern` together with your format pattern. The pattern is a string like `formatPattern: "%{DATETIME} %L  %n: %m"`.

The pattern can contain **format variables** which are replaced by the appropriate values of a log message.

| Variable | Description | Example |
| -------- | ----------- | ------- |
| %{DATETIME} | Date and time | 2004-07-24 18:03:29.015 |
| %{DATETIME_ISO8601} | Date and time (ISO 8601) | 2004-07-24T18:03:29.015 |
| %{DATE} | Date only | 2004-07-24 |
| %{TIME} | Time only | 18:03:29.015 |
| %m | log message | This is a log message. |
| %n | log instance name | my.package.Module |
| %L | upper-case log level name | DEBUG |
| %D | day | 24 |
| %M | month | 07 |
| %Y | year | 2004 |
| %H | hours | 18 |
| %i | minutes | 03 |
| %s | seconds | 29 |
| %S | milliseconds | 015 |
| %T | timestamp | 1090685009015 |
| %% | % literal | % |

Note that several variables can take an optional **padding number** like `%1M` which would result in `7`.

The log instance name will treat a number as the count of name parts. `%1n` would result in `package.Module` and `%0n` would result in `Module`.

The log level name treats a number as right-side space padding count. By default all names are padded to be of equal length.


## Logging
To use the logging framework - assuming it is installed - first of all you need to load it into your module.
```javascript
var Log = require("Logging");
```

Then you create a Log instance with a proper name, e.g. your module package name.
```javascript
var log = new Log("app.security.LoginController");
```

For each log level, the log instance has a method to perform a logging on this level, as well as a method to test if this level is active.

In the default configuration this could be:
```javascript
log.info("User {} accessing login.", username);
// In output produces something like:
// 2004-07-24 18:03:29.015 INFO   app.security.LoginController: User John accessing login.

if (log.isDebug()) {  // False in default configuration, since minimum level is INFO
    log.debug("User data: {}", JSON.stringify(userDAO.getFullUserData(username)));
}
// alternatively:
log.debug(function() {
    // This function is only executed if debug level is active
    return "User data: " + JSON.stringify(userDAO.getFullUserData(username));
    // Note that parameter substitution is not applied when using functions
});
```

A speciality is the **asynchronous logging**. When the function used with a log method takes a parameter, the asynchronous logging mode is used.
This means that you have to call the function provided as the parameter with the desired log message.
```javascript
log.debug(function(done) {
    // Note the function parameter which provides the log callback
    // This function is only executed if debug level is active
    
    userDAO.requestFullUserData(username, function(data) {
        done("User data: " + JSON.stringify(data));
        // Note that parameter substitution is not applied when using functions
        
        done("User name is " + data.name);  // Log callback can be used multiple times
    });
});
```
