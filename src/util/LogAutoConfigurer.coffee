fs = require 'fs'
path = require 'path'
JsonParser = require 'RelaxedJsonParser'


DEFAULT_TYPE = 'ConsoleLogger'


module.exports =

	findAndConfigureLogging: (logfilename) ->
		# Look for logfilename in this and parent directories
		dir = '.'
		last = null
		
		while on
			p = path.resolve dir, logfilename
			break if p is last  # Cannot get any higher
			
			if fs.existsSync(p) and do fs.statSync(p).isFile
				return @createLoggers JsonParser.parse do fs.readFileSync(p).toString
			
			last = p
			dir = if dir is '.' then '..' else "#{dir}/.."
		
		do @createLoggers
	
	
	
	createLoggers: (config = {}) ->
		stdLevels = config.levels ? config.level ? {}
		
		loggers = config.loggers ? config.logger ? config.adapters ? config.adapter ? [ {} ]
		
		loggers = loggers.map (opts) ->
			type = do "#{opts.type ? DEFAULT_TYPE}".trim
			type = "../loggers/#{type}" if /^\w+$/.test type
			
			opts.levels = stdLevels if 'levels' not of opts and 'level' not of opts
			
			clazz = require type
			
			new clazz opts
		
		if loggers.length > 1
			TeePseudoLogger = require '../loggers/TeePseudoLogger'
			new TeePseudoLogger loggers
		
		else
			loggers[0]
