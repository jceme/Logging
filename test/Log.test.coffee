require 'should'
LogLevels = require '../util/LogLevels'


class AdapterMock extends require('../loggers/AbstractLogger')
	
  constructor: ->
  	super
  	@formatPattern = '[%L] %n: %m'
  
  getLevelConfig: (parts) ->
    parts.should.eql @parts
    @level
 
  logMessage: (obj) ->
  	@lastLevel = obj.level.toLowerCase()
  	@lastMessage = obj.msg
  	super
  
  log: (line) -> @lastLine = line
  
  
  setLevel: (lvl) -> @level = if lvl is 'All' then 63 else if lvl is 'Off' then 0 else LogLevels[lvl]
  
  assert: (level, msg) ->
    @lastLevel.should.equal level, 'Mock level check'
    @lastMessage.should.equal msg, 'Mock message check'
  
  assertLine: (line) ->
  	@lastLine.should.equal line

  reset: ->
    @level = 0
    delete @lastLevel
    delete @lastMessage
    delete @lastLine
    

Log = require '../Log'
LogAutoConfigurer = require '../util/LogAutoConfigurer'
ConsoleAdapter = require '../loggers/ConsoleLogger'
FileAdapter = require '../loggers/FileLogger'
TeeAdapter = require '../loggers/TeePseudoLogger'


suite 'Sole logging', ->
  
  test 'Log available', ->
    Log.should.be.type 'function'
  
  
  test 'Log creatable', ->
    (new Log "a").should.be.ok
    (log = (new Log "  foo.bar  ")).should.be.ok
    log.name.should.equal 'foo.bar'
    (new Log "foo.bar.m").should.be.ok
    
    (-> new Log()).should.throw()
    (-> new Log null).should.throw()
    (-> new Log "").should.throw()
    (-> new Log " ").should.throw()
    (-> new Log ".").should.throw()
    (-> new Log ".ab").should.throw()
    (-> new Log "ab.").should.throw()
    (-> new Log ".a.b").should.throw()
    (-> new Log "a..b").should.throw()

suite 'Log configurer', ->
	
	test 'Configurer available', ->
		LogAutoConfigurer.should.be.ok
		LogAutoConfigurer.findAndConfigureLogging.should.be.type 'function'
		LogAutoConfigurer.createLoggers.should.be.type 'function'
	
	test 'Configurer createLoggers', ->
		LogAutoConfigurer.createLoggers().should.be.ok
	

suite 'Logging', ->
  
  mock = null
  deflevel = Log.DEFAULT_LEVEL
  defadapter = Log.DEFAULT_ADAPTER
  
  setup -> Log.setLogger mock = new AdapterMock()
  teardown -> do mock.reset
  
  
  test 'Log output', ->
    mock.setLevel 'All'
    mock.parts = [ 'my', 'testlogger' ]
    
    log = new Log "my.testlogger"
    
    log.fatal 'This is a fatal message'
    mock.assert 'fatal', 'This is a fatal message'
    mock.assertLine '[FATAL] my.testlogger: This is a fatal message'
    
    log.error 'This is a {} message', 'error'
    mock.assert 'error', 'This is a error message'
    
    log.warn 'This {} a {} message', 'is', 'warn'
    mock.assert 'warn', 'This is a warn message'
    
    log.info 'This {1} a {0} message', 'info', 'is'
    mock.assert 'info', 'This is a info message'
    
    log.debug -> 'This is a debug message'
    mock.assert 'debug', 'This is a debug message'
    mock.assertLine '[DEBUG] my.testlogger: This is a debug message'
    
    log.trace 'This is a trace message'
    mock.assert 'trace', 'This is a trace message'
  
  test 'Async Log output', (testdone) ->
    mock.setLevel 'All'
    mock.parts = [ 'my', 'testlogger' ]
    
    log = new Log "my.testlogger"
        
    log.debug (done) -> done 'This is a debug message'
    mock.assert 'debug', 'This is a debug message'
        
    log.debug (done) ->
    	done 'This is a 1 debug message'
    	done 'This is a 2 debug message'
    mock.assert 'debug', 'This is a 2 debug message'
    
    log.debug (done) ->
    	process.nextTick ->
	    	process.nextTick ->
	    		mock.assert 'debug', 'foo bar'
	    		do testdone
	    	done 'foo bar'
  test 'Log Format', ->
  	
  return
  
  test 'Levels', ->
    log = new Log "my test logger", Log.Level.WARN, mock
  
    mock.reset()
    log.info "msg"
    should.not.exist mock.lastMessage
  
    mock.reset()
    log.warn "msg"
    should.exist mock.lastMessage
  
    mock.reset()
    log.debug "msg"
    should.not.exist mock.lastMessage
  
    mock.reset()
    log.error "msg"
    should.exist mock.lastMessage
  
    mock.reset()
    log.fatal "msg"
    should.exist mock.lastMessage
    
    log.level = Log.Level.ALL
  
    mock.reset()
    log.trace "msg"
    should.exist mock.lastMessage
  
    mock.reset()
    log.info "msg"
    should.exist mock.lastMessage
  
    mock.reset()
    log.fatal "msg"
    should.exist mock.lastMessage
    
    log.level = Log.Level.OFF
  
    mock.reset()
    log.trace "msg"
    should.not.exist mock.lastMessage
  
    mock.reset()
    log.info "msg"
    should.not.exist mock.lastMessage
  
    mock.reset()
    log.fatal "msg"
    should.not.exist mock.lastMessage
   
    
  test 'Level fallback', ->
    Log.DEFAULT_LEVEL = Log.Level.ERROR
    log = new Log "testlogger", null, mock
    log.level.should.equal Log.Level.ERROR
    
    Log.DEFAULT_LEVEL = Log.Level.INFO
    log = new Log "testlogger", null, mock
    log.level.should.equal Log.Level.INFO
    
    mock.reset()
    log.info "msg"
    should.exist mock.lastMessage
    
    mock.reset()
    log.debug "msg"
    should.not.exist mock.lastMessage
    
    mock.reset()
    log.trace "msg"
    should.not.exist mock.lastMessage
    
    log.level = Log.Level.DEBUG
    Log.DEFAULT_LEVEL.should.equal Log.Level.INFO
    
    mock.reset()
    log.info "msg"
    should.exist mock.lastMessage
    
    mock.reset()
    log.debug "msg"
    should.exist mock.lastMessage
    
    mock.reset()
    log.trace "msg"
    should.not.exist mock.lastMessage
  
  
  test 'Log messages', ->
    log = new Log "testlogger", Log.Level.DEBUG, mock
    
    mock.reset()
    log.debug 'My normal log message'
    mock.assert 'debug', '[DEBUG] testlogger: My normal log message'
    
    mock.reset()
    log.trace 'My normal log message'
    should.not.exist mock.lastMessage
    
    mock.reset()
    log.warn 'My {} param log message with {} and {} params', 'foo bar', true
    mock.assert 'warn', '[WARN] testlogger: My foo bar param log message with true and undefined params'
    
    mock.reset()
    log.trace 'My {} param log message with {} and {} params', 'foo bar', true
    should.not.exist mock.lastMessage
    
    mock.reset()
    log.info 'My {1} param with {0} before', 42, true
    mock.assert 'info', '[INFO] testlogger: My true param with 42 before'
    
    mock.reset()
    log.info 'My {} param with {2} last and {} next', 42, true, 'bar'
    mock.assert 'info', '[INFO] testlogger: My 42 param with bar last and true next'
    
    mock.reset()
    log.error -> JSON.stringify { foo: "bar" }
    mock.assert 'error', '[ERROR] testlogger: {"foo":"bar"}'
    
    mock.reset()
    executed = no
    log.trace ->
      executed = yes
      'foo'
    should.not.exist mock.lastMessage
    executed.should.be.false
  
  
  test 'Asynchronous log messages', (done) ->
    log = new Log "testlogger", Log.Level.DEBUG, mock
    
    mock.reset()
    log.debug (innerdone) ->
      setTimeout ->
        innerdone 'Async log message'
        mock.assert 'debug', '[DEBUG] testlogger: Async log message'
        done()
      , 20
    should.not.exist mock.lastMessage


  test 'Tee test setup', ->
    mock1 = new AdapterMock()
    mock2 = new AdapterMock()
    
    adapter = new TeeAdapter(mock1, new TeeAdapter(mock2))
    
    log = new Log "testlogger", Log.Level.DEBUG, adapter
    
    should.not.exist mock1.lastMessage
    should.not.exist mock2.lastMessage
    
    log.info 'Count of mocks: {}', 2
    
    mock1.assert 'info', '[INFO] testlogger: Count of mocks: 2'
    mock2.assert 'info', '[INFO] testlogger: Count of mocks: 2'

return


suite 'Logging init', ->
  
  test 'Init without args', ->
    Log.init()
    Log.DEFAULT_LEVEL.should.equal Log.Level.INFO
    Log.DEFAULT_ADAPTER.should.be.an.instanceOf ConsoleAdapter
  
  
  test 'Init from file', ->
    Log.init 'src/test/testconfig.json'
    Log.DEFAULT_LEVEL.should.equal Log.Level.DEBUG
    Log.DEFAULT_ADAPTER.should.be.an.instanceOf TeeAdapter
    Log.DEFAULT_ADAPTER.adapters.length.should.equal 2
    Log.DEFAULT_ADAPTER.adapters[0].should.be.an.instanceOf ConsoleAdapter
    Log.DEFAULT_ADAPTER.adapters[0].minLevel.should.equal Log.Level.ERROR
    Log.DEFAULT_ADAPTER.adapters[0].maxLevel.should.equal Log.Level.OFF
    Log.DEFAULT_ADAPTER.adapters[1].should.be.an.instanceOf ConsoleAdapter
    Log.DEFAULT_ADAPTER.adapters[1].minLevel.should.equal Log.Level.DEBUG
    Log.DEFAULT_ADAPTER.adapters[1].maxLevel.should.equal Log.Level.INFO
    
    Log.init {}
    Log.DEFAULT_LEVEL.should.equal Log.Level.INFO
    Log.DEFAULT_ADAPTER.should.be.an.instanceOf ConsoleAdapter
  
  
  test 'Init from object', ->
    Log.init
      adapters: [
        {
          type: "ConsoleAdapter"
        }
        {
          type: "ConsoleAdapter"
          max:  "WARN"
        }
      ]
    Log.DEFAULT_ADAPTER.should.be.an.instanceOf TeeAdapter
    Log.DEFAULT_ADAPTER.adapters.length.should.equal 2
    Log.DEFAULT_ADAPTER.adapters[0].should.be.an.instanceOf ConsoleAdapter
    Log.DEFAULT_ADAPTER.adapters[0].minLevel.should.equal Log.Level.ALL
    Log.DEFAULT_ADAPTER.adapters[0].maxLevel.should.equal Log.Level.OFF
    Log.DEFAULT_ADAPTER.adapters[1].should.be.an.instanceOf ConsoleAdapter
    Log.DEFAULT_ADAPTER.adapters[1].minLevel.should.equal Log.Level.ALL
    Log.DEFAULT_ADAPTER.adapters[1].maxLevel.should.equal Log.Level.WARN
    
    Log.init {}
    Log.DEFAULT_LEVEL.should.equal Log.Level.INFO
    Log.DEFAULT_ADAPTER.should.be.an.instanceOf ConsoleAdapter
  
  
  test 'Test configured log levels', ->
    Log.init
      levels:
        "": "debug"
        "foo": "warn"
        "foo.bar": "info"
    
    tst = (name, method, logged) ->
      mock = new AdapterMock()
      log = new Log name, null, mock
      log[method] 'msg'
      if logged then mock.lastLevel.should.equal method
      else should.not.exist mock.lastLevel
    
    tst 'gar', 'debug', yes
    tst 'gar', 'trace', no
    tst 'foo', 'debug', no
    tst 'foo', 'warn', yes
    tst 'fool', 'debug', yes
    tst 'foo-bar', 'debug', yes
    tst 'foo.test', 'debug', no
    tst 'foo.test', 'warn', yes
    tst 'foo.bar', 'debug', no
    tst 'foo.bar', 'info', yes
