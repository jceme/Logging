module.exports = class ConsoleAdapter extends require('./Adapter')

  'use strict'
  
  constructor: (_console = console) ->
    super
    @_fatal = _console.error or _console.log
    @_error = _console.error or _console.log
    @_warn =  _console.warn  or _console.log
    @_info =  _console.info  or _console.log
    @_debug = _console.debug or _console.log
    @_trace = _console.debug or _console.log

  toString: -> 'ConsoleAdapter'
