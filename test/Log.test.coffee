class AdapterMock
  "fatal error warn info debug trace".split(' ').forEach (key) ->
    AdapterMock::[key] = (msg) ->
      @lastLevel = key
      @lastMessage = msg
  
  assert: (level, msg) ->
    @lastLevel.should.equal level, 'Mock level check'
    @lastMessage.should.equal msg, 'Mock message check'

  reset: ->
    delete @lastLevel
    delete @lastMessage

Log = require '../src/Log.coffee'
TeeAdapter = require '../src/adapters/TeeAdapter.coffee'
should = require 'should'


suite 'Sole logging', ->
  
  test 'Log available', ->
    Log.should.be.a 'function'
    Log.DEFAULT_LEVEL.should.be.a 'number'
    Log.DEFAULT_ADAPTER.should.be.ok
    Log.Level.should.be.a 'object'
  
  
  test 'Log creatable', ->
    (new Log "foo").should.be.ok
    (new Log "bar", Log.Level.DEBUG).should.be.ok
    (new Log "bar", Log.Level.DEBUG, {}).should.be.ok
    (-> new Log()).should.throw()
    (-> new Log null).should.throw()
    (-> new Log "").should.throw()


suite 'Logging', ->
  
  mock = null
  deflevel = Log.DEFAULT_LEVEL
  defadapter = Log.DEFAULT_ADAPTER
  
  setup -> mock = new AdapterMock()
  teardown ->
    Log.DEFAULT_LEVEL = deflevel
    Log.DEFAULT_ADAPTER = defadapter
  
  
  test 'Log output', ->
    should.exist Log.Level.ALL, 'Class has level ALL'
    Log.DEFAULT_LEVEL = Log.Level.ALL
    
    log = new Log "testlogger", Log.Level.ALL, mock
    
    log.fatal 'This is a fatal message'
    mock.assert 'fatal', '[FATAL] testlogger: This is a fatal message'
    
    log.error 'This is a error message'
    mock.assert 'error', '[ERROR] testlogger: This is a error message'
    
    log.warn 'This is a warn message'
    mock.assert 'warn', '[WARN] testlogger: This is a warn message'
    
    log.info 'This is a info message'
    mock.assert 'info', '[INFO] testlogger: This is a info message'
    
    log.debug 'This is a debug message'
    mock.assert 'debug', '[DEBUG] testlogger: This is a debug message'
    
    log.trace 'This is a trace message'
    mock.assert 'trace', '[TRACE] testlogger: This is a trace message'
  
  
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
