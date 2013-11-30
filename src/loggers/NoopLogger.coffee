module.exports = do ->

	'use strict'

	class NoopLogger extends require('./AbstractLogger')
		
		log: ->
		
		toString: -> 'NoopLogger'
