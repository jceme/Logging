module.exports = class Adapter

  'use strict'
  
  LogLevel = require '../LogLevel'
  
  lclevels = {}
  lclevels[key.toLowerCase()] = val for key, val of LogLevel
  
  minLevel: LogLevel.ALL
  maxLevel: LogLevel.OFF
  
  
  for name in 'fatal error warn info debug trace'.split(' ') then do (name) ->
    Adapter::[name] = -> if @minLevel >= lclevels[name] >= @maxLevel then @["_#{name}"].apply @, arguments
