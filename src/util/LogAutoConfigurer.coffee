
DEFAULT_TYPE = 'ConsoleLogger'


module.exports =

	findAndConfigureLogging: (logfilename, croak) ->
		throw new Error 'File name required' unless logfilename
		
		if /^\//.test logfilename
			# Absolute file name
			logger = @createLoggersFrom logfilename, croak
			return logger if logger?
		
		else
			# Look for logfilename in current working dir and its parents
			dir = '.'
			last = null
			path = require 'path'
			
			while on
				p = path.resolve dir, logfilename
				break if p is last  # Cannot get any higher
				
				logger = @createLoggersFrom p, croak
				return logger if logger?
				
				last = p
				dir += '/..'
		
		@createLoggers null, croak
	
	
	
	createLoggersFrom: (filepath, croak) ->
		fs = require 'fs'
		JsonParser = require 'RelaxedJsonParser'
		
		if fs.existsSync(filepath) and do fs.statSync(filepath).isFile
			try
				content = do fs.readFileSync(filepath).toString
				json = JsonParser.parse content
				return @createLoggers json, croak
			
			catch e
				throw e if croak
		
		null
	
	
	
	createLoggers: (config = {}, croak) ->
		stdLevels = config.levels ? config.level ? {}
		
		loggers = config.loggers ? config.logger ? config.adapters ? config.adapter ? [ {} ]
		
		loggers = loggers.map (opts) ->
			type = do "#{opts.type ? DEFAULT_TYPE}".trim
			type = "../loggers/#{type}" if /^\w+$/.test type
			
			opts.levels = stdLevels if 'levels' not of opts and 'level' not of opts
			
			try
				clazz = require type
				return new clazz opts
			
			catch e
				throw e if croak
			
			null
		
		loggers = loggers.filter (x) -> x
		
		if loggers.length > 1
			TeePseudoLogger = require '../loggers/TeePseudoLogger'
			new TeePseudoLogger loggers
		
		else
			loggers[0]
