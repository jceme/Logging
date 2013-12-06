module.exports = do ->

	# XXX Directly export class with release of CoffeeScript v1.6.4
	'use strict'

	class FileLogger extends require('./AbstractLogger')
		
		fs = require 'fs'
		path = require 'path'
		
		KEYS_FILENAME = [
			'filename'
			'fileName'
			'file'
		]
		
		KEYS_BASEDIR = [
			'basedir'
			'baseDir'
			'dir'
		]
		
		
		cache = {}
		
		@closeAllOpenFiles: ->
			for _, fd of cache then try fs.closeSync fd
			cache = {}
			return
		
		
		process.on 'exit', @closeAllOpenFiles
		
		
		
		constructor: (config) ->
			super
			
			@filename    = config.getOption(KEYS_FILENAME...) or 'logging.log'
			basedir      = config.getOption(KEYS_BASEDIR...) or '.'
			openMode     = config.getOption('mode') ? 0o644
			@throwErrors = config.getOption('throwErrors') ? no
			
			{key, value} = config.getOptionWithKey('flags', 'overwrite', 'append') ? { key: 'append', value: yes }
			openFlags    = if key is 'flags' then value else if (key is 'overwrite' and value) or (key is 'append' and not value) then 'w' else 'a'
			
			filepath = path.resolve basedir, @filename
			
			@fd = cache[filepath] ?= fs.openSync filepath, openFlags, openMode
		
		
		log: (line) ->
			try fs.writeSync @fd, "#{line}\n"
			catch e
				throw e if @throwErrors
			return
		
		toString: -> "FileLogger[#{@filename}]"
