module.exports = class TeeAdapter

  'use strict'

  constructor: (@adapters...) ->
    
  # Create prototype delegates to adapters methods
  for name in 'fatal error warn info debug trace'.split(' ') then do (name) ->
    TeeAdapter::[name] = ->
      for adapter in @adapters then adapter[name].apply adapter, arguments
      return
