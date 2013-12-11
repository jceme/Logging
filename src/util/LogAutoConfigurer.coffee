
'use strict'

Config = require './Config'

DEFAULT_TYPE = 'ConsoleLogger'

KEYS_LOGGERS = [
	'loggers'
	'logger'
	'adapters'
	'adapter'
]


module.exports =

	findAndConfigureLogging: (logfilename) ->
		throw new Error 'File name required' unless logfilename
		
		if /^\//.test logfilename
			# Absolute file name
			logger = @createLoggersFrom logfilename
			return logger if logger?
		
		else
			# Look for logfilename in current working dir and its parents
			dir = '.'
			last = null
			path = require 'path'
			
			while on
				p = path.resolve dir, logfilename
				break if p is last  # Cannot get any higher
				
				logger = @createLoggersFrom p
				return logger if logger?
				
				last = p
				dir += '/..'
		
		@createLoggers new Config()
	
	
	
	createLoggersFrom: (filepath) ->
		fs = require 'fs'
		JsonParser = require 'RelaxedJsonParser'
		
		if fs.existsSync(filepath) and do fs.statSync(filepath).isFile

			content = do fs.readFileSync(filepath).toString
			json = JsonParser.parse content
			return @createLoggers new Config json
		
		null
	
	
	
	createLoggers: (config) ->
		loggers = config.getOption(KEYS_LOGGERS...) ? [ {} ]
		loggers = [ loggers ] unless loggers instanceof Array
		
		config.removeOption KEYS_LOGGERS...
		
		loggers = loggers.map (opts) => @createLogger new Config opts, config
		
		if loggers.length is 1
			loggers[0]
		
		else
			TeePseudoLogger = require '../loggers/TeePseudoLogger'
			new TeePseudoLogger loggers
	
	
	
	createLogger: (config) ->
		clazz = @resolveLoggerType config.getOption 'type'
		new clazz config
	
	
	
	resolveLoggerType: (type = DEFAULT_TYPE) ->
		type = do "#{type}".trim
		
		types = []
		e = /^(\w+)(?:Adapter)?$/i.exec type
		
		types.push "../loggers/#{type}" if e
		types.push type
		types.push "../loggers/#{e[1]}Logger" if e
		
		return require T for T in types when @isResolvableType T
		
		throw new Error "Cannot resolve logger type: #{type}"
	
	
	
	isResolvableType: (type) ->
		try
			require.resolve type
			yes
		catch
			no
