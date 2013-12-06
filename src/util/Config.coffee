module.exports = class Config
	
	'use strict'
	
	
	@filterKeys: (obj, keys...) ->
		f = {}
		f[k] = v for k, v of obj when k not in keys
		f
	
	
	constructor: (@opts = {}, @parent) ->
	
	
	# Find config option by key names in order, else get from parent
	getOption: (keynames...) ->
		opts = @opts
		return opts[key] for key in keynames when key of opts
		
		@parent?.getOption keynames...
	
	
	removeOption: (keynames...) ->
		@opts = Config.filterKeys @opts, keynames...
		return
