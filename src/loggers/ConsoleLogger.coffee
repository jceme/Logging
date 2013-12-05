module.exports = do ->

	'use strict'

	class ConsoleLogger extends require('./AbstractLogger')
		
		constructor: (opts = {}) ->
			super
			_console = opts.console ? console
			
			fn = (fnname) -> (_console[fnname] or _console.log).bind _console
			
			outputs =
				Fatal: f = fn 'error'
				Error: f
				Warn:  fn 'warn'
				Info:  fn 'info'
				Debug: f = fn 'debug'
				Trace: f
		
			@logMessage = (obj) -> outputs[obj.level] @formatLogMessage obj
		
		
		toString: -> 'ConsoleLogger'
