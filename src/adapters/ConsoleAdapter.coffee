module.exports = class ConsoleAdapter
  
  constructor: (_console = console) ->
    @fatal = _console.error or _console.log
    @error = _console.error or _console.log
    @warn =  _console.warn  or _console.log
    @info =  _console.info  or _console.log
    @debug = _console.debug or _console.log
    @trace = _console.debug or _console.log

  toString: -> 'ConsoleAdapter'
