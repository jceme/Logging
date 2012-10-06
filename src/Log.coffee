module.exports = class Log

  'use strict'
  
  @Level =
    OFF: 0
    FATAL: 1
    ERROR: 2
    WARN: 3
    INFO: 4
    DEBUG: 5
    TRACE: 6
    ALL: 100
    
  @DEFAULT_LEVEL = @Level.INFO
  
  @DEFAULT_ADAPTER = require './adapters/ConsoleAdapter'

  rev = {}
  lcrev = {}

  for key, val of @Level when @Level.OFF < val < @Level.ALL then do (key, val) ->
    rev[val] = key
    lcrev[val] = lckey = key.toLowerCase()
    Log::[lckey] = -> log.call @, Log.Level[key], arguments


  constructor: (@name, @level = Log.DEFAULT_LEVEL, @adapter = Log.DEFAULT_ADAPTER) ->
  
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
