module.exports = class Config
	
	'use strict'
	
	
	@filterKeys: (obj, keys...) ->
		f = {}
		f[k] = v for k, v of obj when k not in keys
		f
	
	@extend: (objs...) ->
		f = {}
		f[k] = v for k, v of obj for obj in objs
		f
	
	
	constructor: (@opts = {}, @parent) ->
	
	
	getOption: (keynames...) -> @getOptionWithKey(keynames...)?.value

	
	# Find config option by key names in order, else get from parent
	getOptionWithKey: (keynames...) ->
		opts = @opts
		return key: key, value: opts[key] for key in keynames when key of opts
		
		@parent?.getOptionWithKey keynames...
	
	
	removeOption: (keynames...) ->
		@opts = Config.filterKeys @opts, keynames...
		return
