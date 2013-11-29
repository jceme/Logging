module.exports = class Log
	
	'use strict'
	
	LogLevels = require './LogLevels'
	defineProperty = Object.defineProperty
	
	
	# Log consumer
	Logger = null  # TODO
	
	
	
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
		
		levelConfig = Logger.getLevelConfig nameParts
		
		# Define logger methods
		for level in LogLevels then do (level) ->
			granted = not not levelConfig[level]
			lclevel = do level.toLowerCase
			
			logfunc =
				if granted then (msg, args...) ->
					buildLogMessage msg, args, (logMessage) ->
						Logger[lclevel] level: level, msg: logMessage, name: name, parts: nameParts, date: new Date()
				
				else -> return
			
			defineProperty @, "is#{level}", configurable: yes, enumerable: no, writable: no, value: -> granted
			defineProperty @, lclevel, configurable: yes, enumerable: no, writable: no, value: logfunc
