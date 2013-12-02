module.exports = do ->

	'use strict'

	class FileLogger extends require('./AbstractLogger')
		
		fs = require 'fs'
		path = require 'path'
		
		
		cache = {}
		
		@closeAllOpenFiles: ->
			for _, fd of cache then try fs.closeSync fd
			cache = {}
			return
		
		
		process.on 'exit', @closeAllOpenFiles
		
		
		
		constructor: (opts = {}) ->
			super
			
			filename    = opts.file or opts.filename or 'logging.log'
			openFlags   = opts.openFlags or opts.flags or (if opts.overwrite ? not(opts.append ? yes) then 'w' else 'a')
			openMode    = opts.mode ? 0o644
			throwErrors = opts.throwErrors ? no
			filepath = path.resolve filename
			
			fd = cache[filepath] ?= fs.openSync filepath, openFlags, openMode
			
			@log = (line) ->
				try fs.writeSync fd, "#{line}\n"
				catch e
					throw e if throwErrors
				return
			
			@toString = -> "FileLogger[#{filename}]"
