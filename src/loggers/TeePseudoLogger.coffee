module.exports = class TeePseudoLogger
	
	'use strict'
	
	LogLevels = require '../util/LogLevels'
	
	
	
	constructor: (@loggers = []) ->
	
	
	getLevelConfig: (parts) ->
		masks  = []
		extras = []
		
		for logger in @loggers
			lvlcfg = logger.getLevelConfig parts
			masks.push lvlcfg.mask
			extras.push lvlcfg
		
		mask:  LogLevels.combine masks...
		extra: extras
	
	
	logMessage: (obj) ->
		loggers = @loggers
		{ numLevel, extra } = obj
		
		# Clone message object
		myobj = {}
		myobj[k] = v for k, v of obj
		
		for i in [0 ... loggers.length]
			X = extra[i]
			if LogLevels.isset X.mask, numLevel
				myobj.extra = X.extra
				loggers[i].logMessage myobj
				
		#logger.logMessage obj for logger in @loggers; return
		return
	
	
	toString: -> "TeePseudoLogger[#{@loggers.join ', '}]"
