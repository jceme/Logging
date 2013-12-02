
DEFAULT_TYPE = 'ConsoleLogger'


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
		
		do @createLoggers
	
	
	
	createLoggersFrom: (filepath) ->
		fs = require 'fs'
		JsonParser = require 'RelaxedJsonParser'
		
		if fs.existsSync(filepath) and do fs.statSync(filepath).isFile

			content = do fs.readFileSync(filepath).toString
			json = JsonParser.parse content
			return @createLoggers json
		
		null
	
	
	
	createLoggers: (config = {}) ->
		stdLevels = config.levels ? config.level ? {}
		
		loggers = config.loggers ? config.logger ? config.adapters ? config.adapter ? [ {} ]
		
		loggers = [ loggers ] unless loggers instanceof Array
		
		loggers = loggers.map (opts) ->
			type = do "#{opts.type ? DEFAULT_TYPE}".trim
			type = "../loggers/#{type}" if /^\w+$/.test type
			
			opts.levels = stdLevels if 'levels' not of opts and 'level' not of opts
			
			clazz = require type
			new clazz opts
		
		loggers = loggers.filter (x) -> x
		
		if loggers.length > 1
			TeePseudoLogger = require '../loggers/TeePseudoLogger'
			new TeePseudoLogger loggers
		
		else
			loggers[0]
