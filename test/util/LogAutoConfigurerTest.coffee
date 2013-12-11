require 'should'
assert = require 'assert'
mockery = require 'mockery'
nodemock = require 'nodemock'



suite 'LogAutoConfigurer: Sanity checks', ->
	
	for name in [
		'util/LogAutoConfigurer'
		'loggers/ConsoleLogger'
		'loggers/FileLogger'
		'loggers/NoopLogger'
		'loggers/TeePseudoLogger'
	]
		test "Require ok for #{name}", ->
			obj = null
			fn = -> obj = require "../../#{name}"
			fn.should.not.throwError()
			assert.ok obj
	
	return
	


suite 'LogAutoConfigurer.findAndConfigureLogging', ->
	
	LogAutoConfigurer = _fs = _path = Logger = mocks = null
	
	mkmock = (fnname) ->
		m = nodemock.mock fnname
		mocks.push m
		m
	
	
	suiteSetup -> mockery.enable useCleanCache: yes
	
	suiteTeardown -> do mockery.disable
	
	setup ->
		mocks = []
		mockery.registerMock 'fs', _fs = mkmock('__noop').fail()
		mockery.registerMock 'path', _path = mkmock('__noop').fail()
		mockery.registerAllowables [
			'../../util/LogAutoConfigurer'
			'./Config'
			'RelaxedJsonParser'
			'./PegjsJsonParser'
		]
		LogAutoConfigurer = require '../../util/LogAutoConfigurer'
	
	teardown ->
		do mock.assertThrows for mock in mocks
		mocks = null
		do mockery.deregisterAll
		do mockery.resetCache
		LogAutoConfigurer = _fs = _path = Logger = mocks = null
	
	setResolvable = (expectedType = '../loggers/ConsoleLogger', result = yes, times = 1) ->
		if Logger?
			Logger.mock('_').takes(expectedType).returns(result).times(times)
		else
			Logger = mkmock('_').takes(expectedType).returns(result).times(times)
			LogAutoConfigurer.isResolvableType = Logger._
	
	
	test 'File is null', ->
		(-> LogAutoConfigurer.findAndConfigureLogging()).should.throwError 'File name required'
	
	test 'File is empty', ->
		(-> LogAutoConfigurer.findAndConfigureLogging '').should.throwError 'File name required'
	
	test 'File is relative', ->
		logger = {}
		_path.mock('resolve').takes('.', 'foo.log').returns('/foo/bar/foo.log')
		_path.mock('resolve').takes('./..', 'foo.log').returns('/foo/foo.log')
		_fs.mock('existsSync').takes('/foo/bar/foo.log').returns(no)
		_fs.mock('existsSync').takes('/foo/foo.log').returns(yes)
		_fs.mock('statSync').takes('/foo/foo.log').returns mkmock('isFile').returns(yes)
		_fs.mock('readFileSync').takes('/foo/foo.log').returns '{ loggers: [{ "moo": 29 }] }'
		mockery.registerMock '../loggers/ConsoleLogger', (config) ->
			config.getOption('moo').should.equal 29
			logger
		setResolvable()
		
		LogAutoConfigurer.findAndConfigureLogging('foo.log').should.equal logger
	
	test 'File is absolute', ->
		logger = {}
		_fs.mock('existsSync').takes('/bar/foo.log').returns(yes)
		_fs.mock('statSync').takes('/bar/foo.log').returns mkmock('isFile').returns(yes)
		_fs.mock('readFileSync').takes('/bar/foo.log').returns '{ loggers: { type: "MySpecialTestLogger", "moo": 81 } }'
		mockery.registerMock 'MySpecialTestLogger', (config) ->
			config.getOption('moo').should.equal 81
			logger
		setResolvable '../loggers/MySpecialTestLogger', no
		setResolvable 'MySpecialTestLogger', yes
		
		LogAutoConfigurer.findAndConfigureLogging('/bar/foo.log').should.equal logger
	
	test 'File is absolute and not existing', ->
		logger = {}
		_fs.mock('existsSync').takes('/bar/foo.log').returns(no)
		mockery.registerMock '../loggers/ConsoleLogger', (config) -> logger
		setResolvable()

		LogAutoConfigurer.findAndConfigureLogging('/bar/foo.log').should.equal logger
	
	test 'File is absolute and stats fail', ->
		_fs.mock('existsSync').takes('/bar/foo.log').returns(yes)
		_fs.statSync = (path) -> throw new Error "Stat failed for #{path}"
		
		(-> LogAutoConfigurer.findAndConfigureLogging('/bar/foo.log')).should.throwError 'Stat failed for /bar/foo.log'
	
	test 'File is absolute with invalid content', ->
		_fs.mock('existsSync').takes('/bar/foo.log').returns(yes)
		_fs.mock('statSync').takes('/bar/foo.log').returns mkmock('isFile').returns(yes)
		_fs.mock('readFileSync').takes('/bar/foo.log').returns '}}'
		
		(-> LogAutoConfigurer.findAndConfigureLogging('/bar/foo.log')).should.throwError()
	
	test 'No more parent dir', ->
		logger = {}
		_path.mock('resolve').takes('.', 'foo.log').returns('/foo.log')
		_path.mock('resolve').takes('./..', 'foo.log').returns('/foo.log')
		_fs.mock('existsSync').takes('/foo.log').returns(no)
		mockery.registerMock '../loggers/ConsoleLogger', (config) -> logger
		setResolvable()
			
		LogAutoConfigurer.findAndConfigureLogging('foo.log').should.equal logger



suite 'LogAutoConfigurer.createLoggers', ->
	
	LogAutoConfigurer = Config = Logger = mocks = null
	
	mkmock = (fnname) ->
		m = nodemock.mock fnname
		mocks.push m
		m
	
	
	suiteSetup -> mockery.enable useCleanCache: yes
	
	suiteTeardown -> do mockery.disable
	
	setup ->
		mocks = []
		mockery.registerAllowables [
			'../../util/LogAutoConfigurer'
			'./Config'
			'../../util/Config'
		]
		Config = require '../../util/Config'
		LogAutoConfigurer = require '../../util/LogAutoConfigurer'
		LogAutoConfigurer.isResolvableType = -> throw new Error 'Method must be replaced in test'
	
	teardown ->
		do mock.assertThrows for mock in mocks
		mocks = null
		do mockery.deregisterAll
		do mockery.resetCache
		LogAutoConfigurer = Logger = mocks = null
	
	setResolvable = (expectedType = '../loggers/ConsoleLogger', result = yes, times = 1) ->
		if Logger?
			Logger.mock('_').takes(expectedType).returns(result).times(times)
		else
			Logger = mkmock('_').takes(expectedType).returns(result).times(times)
			LogAutoConfigurer.isResolvableType = Logger._
	
	
	test 'No spec', ->
		logger = {}
		mockery.registerMock '../loggers/ConsoleLogger', (config) -> logger
		setResolvable()
		
		LogAutoConfigurer.createLoggers(new Config()).should.equal logger
	
	test 'Single Private type logger', ->
		logger = {}
		mockery.registerMock 'my/test/PrivateLogger', (config) ->
			config.getOption('levels').should.eql { 'abc': 'DEBUG' }
			logger
		setResolvable('my/test/PrivateLogger')
		
		LogAutoConfigurer.createLoggers(new Config loggers: { type: 'my/test/PrivateLogger' }, levels: { 'abc': 'DEBUG' }).should.equal logger
	
	test 'Spec with global option', ->
		logger = {}
		mockery.registerMock '../loggers/ConsoleLogger', (config) ->
			config.getOption('foo').should.equal 'bar'
			logger
		setResolvable()
		
		LogAutoConfigurer.createLoggers(new Config foo: 'bar').should.equal logger
	
	test 'Spec is empty', ->
		logger = {}
		mockery.registerMock '../loggers/ConsoleLogger', (config) -> logger
		setResolvable()
		
		LogAutoConfigurer.createLoggers(new Config()).should.equal logger
	
	for name in [ 'loggers', 'logger', 'adapters', 'adapter' ] then do (name) ->
		test "Spec with sole #{name}", ->
			logger = {}
			act = {}
			act[name] = foo: 'bar'
			mockery.registerMock '../loggers/ConsoleLogger', (config) ->
				config.getOption('foo').should.equal 'bar'
				logger
			setResolvable()
			
			LogAutoConfigurer.createLoggers(new Config act).should.equal logger
		
		test "Spec with multiple sole #{name}", ->
			[ l1, l2, l3, l4 ] = [ {}, {}, {}, {} ]
			act = {}
			act[name] = [{ foo: 'bar' }, { type: 'MySpecialTestType', bar: 'test' }, { type: 'foo/bar/MySpecialTestType', bar: 'foo' }]
			mockery.registerMock '../loggers/ConsoleLogger', (config) ->
				config.getOption('foo').should.equal 'bar'
				l1
			setResolvable()
			#mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(foo: 'bar', levels: {}).returns(l1)._
			mockery.registerMock '../loggers/MySpecialTestType', (config) ->
				config.getOption('bar').should.equal 'test'
				l2
			setResolvable('../loggers/MySpecialTestType')
			#mockery.registerMock '../loggers/MySpecialTestType', mkmock('_').takes(bar: 'test', levels: {}).returns(l2)._
			mockery.registerMock 'foo/bar/MySpecialTestType', (config) ->
				config.getOption('bar').should.equal 'foo'
				l3
			setResolvable('foo/bar/MySpecialTestType')
			#mockery.registerMock 'foo/bar/MySpecialTestType', mkmock('_').takes(bar: 'foo', levels: {}).returns(l3)._
			mockery.registerMock '../loggers/TeePseudoLogger', mkmock('_').takes([ l1, l2, l3 ]).returns(l4)._
			
			LogAutoConfigurer.createLoggers(new Config act).should.equal l4
	
	test 'Type not found', ->
		setResolvable '../loggers/NonExistingLoggerType', no
		setResolvable 'NonExistingLoggerType', no
		setResolvable '../loggers/NonExistingLoggerTypeLogger', no
		
		(-> LogAutoConfigurer.createLoggers(new Config { loggers: [type: 'NonExistingLoggerType'] })).should.throwError /NonExistingLoggerType/
	
	test 'Type not found between others', ->
		logger = {}
		mockery.registerMock '../loggers/ConsoleLogger', (config) ->
			config.getOption('foo').should.equal 4
			logger
		setResolvable()
		
		setResolvable '../loggers/NonExistingLoggerType', no
		setResolvable 'NonExistingLoggerType', no
		setResolvable '../loggers/NonExistingLoggerTypeLogger', no
		
		(-> LogAutoConfigurer.createLoggers(new Config { loggers: [{foo: 4}, {type: 'NonExistingLoggerType'}, {bar: 9}] })).should.throwError /NonExistingLoggerType/
	
	test 'Logger creation fails', ->
		mockery.registerMock '../loggers/ConsoleLogger', (opts) -> throw new Error 'Test error'
		setResolvable()
		
		(-> LogAutoConfigurer.createLoggers(new Config {})).should.throwError 'Test error'
