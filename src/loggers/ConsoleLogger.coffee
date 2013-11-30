module.exports = do ->

	'use strict'

	class ConsoleLogger extends require('./AbstractLogger')
		
		constructor: (opts = {}) ->
			super
			_console = opts.console ? console
			
			@outputs = outputs =
				Fatal: (_console.error or _console.log).bind _console
				Warn:  (_console.warn  or _console.log).bind _console
				Info:  (_console.info  or _console.log).bind _console
				Debug: (_console.debug or _console.log).bind _console
			
			outputs.Error = outputs.Fatal
			outputs.Trace = outputs.Debug
		
		
		logMessage: (obj) ->
			log = @outputs[obj.level] ? @outputs.Info
			log formatLogMessage obj
		
		
		toString: -> 'ConsoleLogger'
