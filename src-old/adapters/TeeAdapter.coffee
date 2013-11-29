module.exports = class TeeAdapter extends require('./Adapter')

  'use strict'

  constructor: (@adapters...) ->
    super
    @adapters = adapters[0] if arguments.length is 1 and adapters[0] instanceof Array
  
  toString: -> 'TeeAdapter'
    
  # Create prototype delegates to adapters methods
  for name in 'fatal error warn info debug trace'.split(' ') then do (name) ->
    TeeAdapter::[name] = ->
      for adapter in @adapters then adapter[name].apply adapter, arguments
      return
