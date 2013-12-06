module.exports = do ->

	# XXX Directly export class with release of CoffeeScript v1.6.4
	'use strict'

	class ConsoleLogger extends require('./AbstractLogger')
		
		constructor: (config, _console = console) ->
			super
			
			fn = (fnname) -> (_console[fnname] or _console.log).bind _console
			
			@outputs =
				Fatal: f = fn 'error'
				Error: f
				Warn:  fn 'warn'
				Info:  fn 'info'
				Debug: f = fn 'debug'
				Trace: f
		
		
		logMessage: (obj) -> @outputs[obj.level] @formatLogMessage obj
		
		toString: -> 'ConsoleLogger'
