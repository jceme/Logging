require 'should'
nodemock = require 'nodemock'


suite 'ConsoleLogger methods', ->
	
	ConsoleLogger = Config = LogLevels = mocks = allLevels = null
	
	mkmock = (fnname) ->
		m = nodemock.mock fnname
		mocks.push m
		m
	
	setup ->
		mocks = []
		ConsoleLogger = require '../../loggers/ConsoleLogger'
		Config = require '../../util/Config'
		LogLevels = require '../../util/LogLevels'
		allLevels = ( k for k of LogLevels )
	
	teardown ->
		do mock.assertThrows for mock in mocks
		mocks = null
	
	test 'Default console ok', ->
		new ConsoleLogger(new Config()).should.be.ok
	
	test 'Appropriate console methods called', ->
		testconsole = mkmock('__noop').fail()
		M =
			Fatal: 'error'
			Error: 'error'
			Warn:  'warn'
			Info:  'info'
			Debug: 'debug'
			Trace: 'debug'
		testconsole.mock(v).takes("My #{k} message") for k, v of M
		
		L = new ConsoleLogger new Config(format: '%m', levels: { '': 'ALL' }), testconsole
		L.should.be.ok
		L.toString().should.be.ok
		
		for lvl in allLevels then L.logMessage
			level: lvl
			numLevel: LogLevels[lvl]
			msg: "My #{lvl} message"
			name: "foo"
			parts: ["foo"]
	
	test 'Use fall-back methods', ->
		testconsole = mkmock('__noop').fail()
		testconsole.mock('log').takes("My #{k} message") for k in allLevels
		
		L = new ConsoleLogger new Config(format: '%m', levels: { '': 'ALL' }), testconsole
		L.should.be.ok
		
		for lvl in allLevels then L.logMessage
			level: lvl
			numLevel: LogLevels[lvl]
			msg: "My #{lvl} message"
			name: "foo"
			parts: ["foo"]
