module.exports = class FileAdapter extends require('./Adapter')

  'use strict'
  
  fs = require 'fs'
  path = require 'path'
  
  
  cache = {}
  
  openFile = (filename, opts) ->
    filepath = path.resolve filename
    cache[filepath] = fs.openSync filepath, opts.openFlags ? (if opts.overwrite then 'w' else 'a'), opts.mode ? 0o644
  
  cachedFile = (filename, opts) ->
    filepath = path.resolve filename
    cache[filepath] ? openFile filepath, opts
  
  
  constructor: (filename, opts = {}) ->
    super
    @fd = if opts.nocache then openFile(filename, opts) else cachedFile(filename, opts)
  
  toString: -> 'FileAdapter'
  
  close: -> try fs.closeSync @fd
    
  # Create prototype methods
  for name in 'fatal error warn info debug trace'.split(' ') then do (name) ->
    FileAdapter::["_#{name}"] = (msg) ->
      msg = msg.replace "\n", "\n    "
      fs.writeSync @fd, "#{msg}\n"
