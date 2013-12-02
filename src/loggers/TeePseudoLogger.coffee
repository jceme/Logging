module.exports = do ->

	'use strict'

	class TeePseudoLogger
		
		constructor: (@loggers = []) ->
		
		
		getLevelConfig: (parts) -> @loggers.map((logger) -> logger.getLevelConfig parts).reduce ((p, c) -> p | c), 0
		
		
		logMessage: (obj) -> logger.logMessage obj for logger in @loggers; return
		
		
		toString: -> "TeePseudoLogger[#{@loggers.join ', '}]"
