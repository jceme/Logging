module.exports =
  ((console) ->
    fatal: console.error or console.log
    error: console.error or console.log
    warn:  console.warn  or console.log
    info:  console.info  or console.log
    debug: console.debug or console.log
    trace: console.debug or console.log
    
    toString: -> 'ConsoleAdapter'
  )(console)
