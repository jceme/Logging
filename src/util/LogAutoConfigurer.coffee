fs = require 'fs'
path = require 'path'
JsonParser = require 'RelaxedJsonParser'


DEFAULT_TYPE = 'ConsoleLogger'


module.exports =

	findAndConfigureLogging: (logfilename) ->
		if /^\//.test logfilename
			# Absolute file name
			if fs.existsSync(logfilename) and do fs.statSync(logfilename).isFile
				return @createLoggers JsonParser.parse do fs.readFileSync(logfilename).toString
		
		else
			# Look for logfilename in current working dir and its parents
			dir = '.'
			last = null
			
			while on
				p = path.resolve dir, logfilename
				break if p is last  # Cannot get any higher
				
				if fs.existsSync(p) and do fs.statSync(p).isFile
					try
						json = JsonParser.parse do fs.readFileSync(p).toString
						return @createLoggers json
				
				last = p
				dir += '/..'
		
		do @createLoggers
	
	
	
	createLoggers: (config = {}) ->
		stdLevels = config.levels ? config.level ? {}
		
		loggers = config.loggers ? config.logger ? config.adapters ? config.adapter ? [ {} ]
		
		loggers = loggers.map (opts) ->
			type = do "#{opts.type ? DEFAULT_TYPE}".trim
			type = "../loggers/#{type}" if /^\w+$/.test type
			
			opts.levels = stdLevels if 'levels' not of opts and 'level' not of opts
			
			try
				clazz = require type
				new clazz opts
			catch
				null
		
		loggers = loggers.filter (x) -> x
		
		if loggers.length > 1
			TeePseudoLogger = require '../loggers/TeePseudoLogger'
			new TeePseudoLogger loggers
		
		else
			loggers[0]
