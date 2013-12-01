module.exports = do ->

	'use strict'

	class FileLogger extends require('./AbstractLogger')
		
		fs = require 'fs'
		path = require 'path'
		
		
		cache = {}
		
		@closeAllOpenFiles: (croak) ->
			for _, fd of cache
				try
					fs.closeSync fd
				
				catch e
					throw e if croak
			
			cache = {}
			return
		
		
		process.on 'exit', => do @closeAllOpenFiles
		
		
		
		constructor: (opts = {}, @croak) ->
			super
			
			filepath = path.resolve opts.file or opts.filename or 'logging.log'
			@fd = cache[filepath] ?= fs.openSync filepath, opts.openFlags or opts.flags or (if opts.overwrite ? not(opts.append ? yes) then 'w' else 'a'), opts.mode ? 0o644
		
		
		log: (line) ->
			try
				fs.writeSync @fd, "#{line}\n"
				
			catch e
				throw e if @croak
		
		
		toString: -> 'FileLogger'
