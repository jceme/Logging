module.exports = class Log
	
	'use strict'
	
	LogLevels = require './util/LogLevels'
	
	defineProperty = Object.defineProperty
	
	DEFAULT_LOGCONFIG = 'logconf.json'
	
	
	# Log consumer
	Logger = null
	
	@initLogging: (configfile) =>
		logger = require('./util/LogAutoConfigurer').findAndConfigureLogging configfile or DEFAULT_LOGCONFIG
		@setLogger logger
	
	@setLogger: (logger) ->
		if not logger? or typeof logger.getLevelConfig isnt 'function' or typeof logger.logMessage isnt 'function'
			throw new Error 'Logger not usable'
		
		Logger = logger
		return
	
	
	do @initLogging
	
	
	
	buildLogMessage = (msg, args, callback) ->
		if typeof msg is 'function'
			if msg.length
				# Have asynchronous log message function
				msg (asyncLogMessage) -> callback asyncLogMessage
				
			else
				# Have log message function
				callback do msg
		
		else
			# Format string message with the arguments
			i = 0
			callback "#{msg}".replace /\{(\d*)\}/g, (_, idx) ->
				args[if idx then parseInt idx, 10 else i++]
		
		return
	
	
	
	# Log producer
	constructor: (name) ->
		throw new Error 'Logger name required' if typeof name isnt 'string' or not (name = do name.trim)
		
		nameParts = name.split /\./
		throw new Error "Invalid logger name: #{name}" unless nameParts.every (p) -> p
		
		# Expose logger name
		defineProperty @, 'name', enumerable: yes, get: -> name
		
		levelConfig = Logger.getLevelConfig(nameParts) ? 0
		
		# Define logger methods
		for levelname, level of LogLevels then do (levelname, level) =>
			granted = not not (levelConfig & level)
			
			logfunc =
				if granted then (msg, args...) ->
					buildLogMessage msg, args, (logMessage) ->
						Logger.logMessage
							level: levelname
							msg: logMessage
							name: name
							parts: nameParts
							date: new Date()
				
				else -> return
			
			defineProperty @, "is#{levelname}", configurable: yes, enumerable: no, writable: no, value: -> granted
			defineProperty @, do levelname.toLowerCase, configurable: yes, enumerable: no, writable: no, value: logfunc
