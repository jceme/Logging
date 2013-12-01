require 'should'
assert = require 'assert'
fs = require 'fs'
path = require 'path'
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
	
	LogAutoConfigurer = _fs = _path = mocks = null
	
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
			'RelaxedJsonParser'
			'./PegjsJsonParser'
		]
		LogAutoConfigurer = require '../../util/LogAutoConfigurer'
	
	teardown ->
		do mock.assertThrows for mock in mocks
		mocks = null
		do mockery.deregisterAll
		do mockery.resetCache
	
	
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
		mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(moo: 29, levels: {}).returns(logger)._
		
		LogAutoConfigurer.findAndConfigureLogging('foo.log', on).should.equal logger
	
	test 'File is absolute', ->
		logger = {}
		_fs.mock('existsSync').takes('/bar/foo.log').returns(yes)
		_fs.mock('statSync').takes('/bar/foo.log').returns mkmock('isFile').returns(yes)
		_fs.mock('readFileSync').takes('/bar/foo.log').returns '{ loggers: [{ type: "MySpecialTestLogger", "moo": 81 }] }'
		mockery.registerMock '../loggers/MySpecialTestLogger', mkmock('_').takes(moo: 81, levels: {}).returns(logger)._
		
		LogAutoConfigurer.findAndConfigureLogging('/bar/foo.log', on).should.equal logger
	
	test 'File is absolute and not existing', ->
		logger = {}
		_fs.mock('existsSync').takes('/bar/foo.log').returns(no)
		mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(levels: {}).returns(logger)._
		
		LogAutoConfigurer.findAndConfigureLogging('/bar/foo.log', on).should.equal logger
	
	test 'File is absolute and stats fail', ->
		_fs.mock('existsSync').takes('/bar/foo.log').returns(yes)
		_fs.statSync = (path) -> throw new Error "Stat failed for #{path}"
		
		(-> LogAutoConfigurer.findAndConfigureLogging('/bar/foo.log', on)).should.throwError 'Stat failed for /bar/foo.log'
	
	test 'File is absolute with invalid content', ->
		_fs.mock('existsSync').takes('/bar/foo.log').returns(yes)
		_fs.mock('statSync').takes('/bar/foo.log').returns mkmock('isFile').returns(yes)
		_fs.mock('readFileSync').takes('/bar/foo.log').returns '}}'
		
		(-> LogAutoConfigurer.findAndConfigureLogging('/bar/foo.log', on)).should.throwError()
	
	test 'File is absolute with invalid content failing silently', ->
		logger = {}
		_fs.mock('existsSync').takes('/bar/foo.log').returns(yes)
		_fs.mock('statSync').takes('/bar/foo.log').returns mkmock('isFile').returns(yes)
		_fs.mock('readFileSync').takes('/bar/foo.log').returns '}}'
		mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(levels: {}).returns(logger)._
		
		LogAutoConfigurer.findAndConfigureLogging('/bar/foo.log', off).should.equal logger
	
	test 'No more parent dir', ->
		logger = {}
		_path.mock('resolve').takes('.', 'foo.log').returns('/foo.log')
		_path.mock('resolve').takes('./..', 'foo.log').returns('/foo.log')
		_fs.mock('existsSync').takes('/foo.log').returns(no)
		mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(levels: {}).returns(logger)._
			
		LogAutoConfigurer.findAndConfigureLogging('foo.log', on).should.equal logger



suite 'LogAutoConfigurer.createLoggers', ->
	
	LogAutoConfigurer = mocks = null
	
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
		]
		LogAutoConfigurer = require '../../util/LogAutoConfigurer'
	
	teardown ->
		do mock.assertThrows for mock in mocks
		mocks = null
		do mockery.deregisterAll
		do mockery.resetCache
	
	
	test 'Spec is null', ->
		logger = {}
		mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(levels: {}).returns(logger)._
		
		LogAutoConfigurer.createLoggers(null, on).should.equal logger
	
	test 'Spec with garbage', ->
		logger = {}
		mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(levels: {}).returns(logger)._
		
		LogAutoConfigurer.createLoggers({ foo: 'bar' }, on).should.equal logger
	
	test 'Spec is empty', ->
		logger = {}
		mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(levels: {}).returns(logger)._
		
		LogAutoConfigurer.createLoggers({}, on).should.equal logger
	
	for name in [ 'levels', 'level' ] then do (name) ->
		test "Spec with sole #{name}", ->
			logger = {}
			act = {}
			act[name] = { foo: 'bar' }
			mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(levels: { foo: 'bar' }).returns(logger)._
			
			LogAutoConfigurer.createLoggers(act, on).should.equal logger
	
	for name in [ 'loggers', 'logger', 'adapters', 'adapter' ] then do (name) ->
		test "Spec with sole #{name}", ->
			logger = {}
			act = {}
			act[name] = [{ foo: 'bar' }]
			mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(foo: 'bar', levels: {}).returns(logger)._
			
			LogAutoConfigurer.createLoggers(act, on).should.equal logger
		
		test "Spec with multiple sole #{name}", ->
			[ l1, l2, l3, l4 ] = [ {}, {}, {}, {} ]
			act = {}
			act[name] = [{ foo: 'bar' }, { type: 'MySpecialTestType', bar: 'test' }, { type: 'foo/bar/MySpecialTestType', bar: 'foo' }]
			mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(foo: 'bar', levels: {}).returns(l1)._
			mockery.registerMock '../loggers/MySpecialTestType', mkmock('_').takes(bar: 'test', levels: {}).returns(l2)._
			mockery.registerMock 'foo/bar/MySpecialTestType', mkmock('_').takes(bar: 'foo', levels: {}).returns(l3)._
			mockery.registerMock '../loggers/TeePseudoLogger', mkmock('_').takes([ l1, l2, l3 ]).returns(l4)._
			
			LogAutoConfigurer.createLoggers(act, on).should.equal l4
	
	for name in [ 'levels', 'level' ] then do (name) ->
		test "Spec with custom logger config in #{name}", ->
			logger = {}
			act = {}
			act[name] = { foo: 'bar' }
			exp = {}
			exp[name] = { foo: 'bar' }
			mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(exp).returns(logger)._
			
			LogAutoConfigurer.createLoggers({ loggers: [ act ], levels: { foo: 'test' } }, on).should.equal logger
	
	test 'Type not found', ->
		mockery.registerAllowable '../loggers/NonExistingLoggerType'
		
		(-> LogAutoConfigurer.createLoggers({ loggers: [type: 'NonExistingLoggerType'] }, on)).should.throwError /NonExistingLoggerType/
	
	test 'Type not found after others', ->
		logger = {}
		mockery.registerAllowable '../loggers/NonExistingLoggerType'
		mockery.registerMock '../loggers/ConsoleLogger', mkmock('_').takes(foo: 4, levels: {}).returns(logger)._
		
		(-> LogAutoConfigurer.createLoggers({ loggers: [{foo: 4}, {type: 'NonExistingLoggerType'}, {bar: 9}] }, on)).should.throwError /NonExistingLoggerType/
	
	test 'Type not found before others', ->
		mockery.registerAllowable '../loggers/NonExistingLoggerType'
		
		(-> LogAutoConfigurer.createLoggers({ loggers: [{type: 'NonExistingLoggerType'}, {bar: 9}] }, on)).should.throwError /NonExistingLoggerType/
	
	test 'Type not found silent', ->
		mockery.registerAllowable '../loggers/NonExistingLoggerType'
		
		assert.equal LogAutoConfigurer.createLoggers({ loggers: [type: 'NonExistingLoggerType'] }, off), null
	
	test 'Type not found silent between others', ->
		[ l1, l2, l3 ] = [ {}, {}, {} ]
		mockery.registerAllowable '../loggers/NonExistingLoggerType'
		cm = mkmock('_').takes(foo: 4, levels: {}).returns(l1)
		cm.mock('_').takes(bar: 9, levels: {}).returns(l2)
		mockery.registerMock '../loggers/ConsoleLogger', cm._
		mockery.registerMock '../loggers/TeePseudoLogger', mkmock('_').takes([ l1, l2 ]).returns(l3)._
		
		LogAutoConfigurer.createLoggers({ loggers: [{foo: 4}, {type: 'NonExistingLoggerType'}, {bar: 9}] }, off).should.equal l3
	
	test 'Logger creation fails', ->
		mockery.registerMock '../loggers/ConsoleLogger', (opts) ->
			opts.should.eql levels: {}
			throw new Error 'Test error'
		
		(-> LogAutoConfigurer.createLoggers({}, on)).should.throwError 'Test error'
	
	test 'Logger creation fails silent', ->
		mockery.registerMock '../loggers/ConsoleLogger', (opts) ->
			opts.should.eql levels: {}
			throw new Error 'Test error'
		
		assert not LogAutoConfigurer.createLoggers {}, off
