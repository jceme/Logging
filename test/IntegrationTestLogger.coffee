module.exports = class extends require '../loggers/ConsoleLogger'
	
	constructor: (config) ->
		@buffer = []
		super config, log: (line) => @buffer.push line
