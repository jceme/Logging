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
		
		@_maskMode: (mode) -> mode & (~process.umask())
		
		@_getModes: (openMode) =>
			if openMode?
				# Set execute flag for each u,g,o if read or write permitted
				msk = (test, setflag) -> openMode | ( if openMode & test then setflag else 0 )
				dirMode = msk(0o006, 0o001) | msk(0o060, 0o010) | msk(0o600, 0o100)
			else
				openMode = @_maskMode 0o644
				dirMode  = @_maskMode 0o755
			
			[openMode, dirMode]
		
		
		process.on 'exit', @closeAllOpenFiles
		
		
		
		constructor: (config) ->
			super
			
			@filename    = config.getOption(KEYS_FILENAME...) or 'logging.log'
			basedir      = config.getOption(KEYS_BASEDIR...) or '.'
			@throwErrors = config.getOption('throwErrors') ? no
			
			filepath = path.resolve basedir, @filename
			@fd = cache[filepath]
			
			unless @fd?
				{key, value} = config.getOptionWithKey('flags', 'overwrite', 'append') ? { key: 'append', value: yes }
				openFlags    = if key is 'flags' then value else if (key is 'overwrite' and value) or (key is 'append' and not value) then 'w' else 'a'
				
				[openMode, dirMode] = FileLogger._getModes config.getOption 'mode'
				
				filedir  = path.dirname filepath
				
				require('mkdirp').sync filedir, dirMode unless fs.existsSync filedir
				
				@fd = cache[filepath] = fs.openSync filepath, openFlags, openMode
		
		
		log: (line) ->
			try fs.writeSync @fd, "#{line}\n"
			catch e
				throw e if @throwErrors
			return
		
		toString: -> "FileLogger[#{@filename}]"
