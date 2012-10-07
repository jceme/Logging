module.exports = class Log

  'use strict'

  ConsoleAdapter = require './adapters/ConsoleAdapter'
  FileAdapter = require './adapters/FileAdapter'
  TeeAdapter = require './adapters/TeeAdapter'
  
  @Level = require './LogLevel'
    
  @DEFAULT_LEVEL = null
  
  @DEFAULT_ADAPTER = null
  
  @LOGFILE_NAME = 'logconf.json'
  
  levels = null
  
  reset = ->
    Log.DEFAULT_LEVEL = Log.Level.INFO
    Log.DEFAULT_ADAPTER = new ConsoleAdapter()
    levels = {}
    

  rev = {}
  lcrev = {}

  for key, val of @Level when @Level.OFF < val < @Level.ALL then do (key, val) ->
    rev[val] = key
    lcrev[val] = lckey = key.toLowerCase()
    Log::[lckey] = -> log.call @, Log.Level[key], arguments
  
  
  getLevel = (levelname) -> Log.Level[(levelname or '').toUpperCase()]
  
  initLogging = (json) ->
    json = JSON.parse json if typeof json is 'string'
    adapters = json.adapters ? json.adapter or []

    reset()
    
    if adapters.length
      Log.DEFAULT_ADAPTER = if adapters.length is 1 then createAdapter adapters[0] else
        new TeeAdapter(( createAdapter adapter for adapter in adapters ))
    
    for name, lvl of json.levels ? json.level or {}
      if (lvl = getLevel lvl)?
        if name then levels[name] = lvl else Log.DEFAULT_LEVEL = lvl
    return
  
  createAdapter = (conf) ->
    adapter = switch conf?.type
      when 'FileAdapter' then new FileAdapter(conf.file ? conf.filename or 'logging.log', conf.opts)
      else new ConsoleAdapter()
    
    adapter.minLevel = n if (n = getLevel conf.min ? conf.minLevel ? conf.minlevel ? conf.minimumLevel)?
    adapter.maxLevel = n if (n = getLevel conf.max ? conf.maxLevel ? conf.maxlevel ? conf.maximumLevel)?
    
    adapter
  
  
  @init: (file) ->
    try
      fs = require 'fs'
      path = require 'path'
      
      unless file?
        # Look for LOGFILE_NAME in this and parent directories
        dir = '.'
        last = null
        while on
          p = path.resolve dir, Log.LOGFILE_NAME
          break if p is last
          
          if fs.existsSync(p) and fs.statSync(p).isFile()
            initLogging fs.readFileSync(p).toString()
            break
          
          last = p
          dir = if dir is '.' then '..' else "#{dir}/.."
      
      else if typeof file is 'string'
        # Treat file as file name and init logging from its content
        initLogging fs.readFileSync(file).toString()
      
      else
        # Treat argument as parsed content
        initLogging file
    
    catch e
      console?.log?("Error while initializing logging: #{e.stack ? e}")
    
    return
  
  @init()
  
  
  # Find the log name prefix (dot-separated) in the configured levels
  findLogLevel = (name) ->
    return levels[name] if name of levels
    
    i = name.length
    while --i > 0 then if name[i] is '.'
      return levels[n] if (n = name.substr 0, i) of levels
    
    return Log.DEFAULT_LEVEL


  constructor: (@name, @level = findLogLevel(name), @adapter = Log.DEFAULT_ADAPTER) ->
    throw new Error('Log name required') unless name
  
  toString: -> "Log[#{@name} at level #{rev[@level]}]"
  
  
  shift = [].shift
  
  log = (level, args) -> if level <= @level
    msg = shift.call args
    
    func = if typeof msg is "function"
      # Have function, if it is not asynchronous then transform it into one
      if msg.length > 0 then msg else (done) -> done msg()
      
    else (done) ->
      # Format message with the arguments
      i = 0
      
      done "#{msg}".replace /\{(?:(\d*)| (.*?))\}/g, (_, idx, str) ->
        unless idx? then str
        else args[if idx is '' then i++ else parseInt idx]
    
    # Execute logging function with done callback
    func (msg) => @adapter[lcrev[level]] "[#{rev[level]}] #{@name}: #{msg}"
    
    return
