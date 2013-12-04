require 'should'
assert = require 'assert'



suite 'AbstractLogger: Sanity checks', ->
	
	test "Require ok for loggers/AbstractLogger", ->
		obj = null
		fn = -> obj = require "../../loggers/AbstractLogger"
		fn.should.not.throwError()
		assert.ok obj
	


suite 'AbstractLogger.constructor', ->
	
	AbstractLogger = LogLevels = null
	
	cmb = (lvls) -> LogLevels.combineLevels lvls.split(/\s+/)...
	
	setup ->
		AbstractLogger = require "../../loggers/AbstractLogger"
		LogLevels = require "../../util/LogLevels"
	
	
	test 'No args', ->
		assert.ok L = new AbstractLogger()
		L.levelConfig.should.eql '': cmb 'Info Warn Error Fatal'
		L.formatPattern.should.be.type('string')
		L.formatPattern.should.be.ok
	
	for name in [ 'levels', 'level' ] then do (name) ->
		test "Spec with sole #{name}", ->
			act = {}
			act[name] = { 'foo': 'Trace', 'foo.bar': 'error', 'abc': ['DEBUG', 'waRN'] }
			
			assert.ok L = new AbstractLogger act
			L.levelConfig.should.eql
				'': cmb 'Info Warn Error Fatal'
				'foo': cmb 'Trace Debug Info Warn Error Fatal'
				'foo.bar': cmb 'Error Fatal'
				'abc': cmb 'Debug Warn'
	
	test 'With default level', ->
		assert.ok L = new AbstractLogger levels: { '': 'Trace', 'foo.bar': 'error' }
		L.levelConfig.should.eql
			'': cmb 'Trace Debug Info Warn Error Fatal'
			'foo.bar': cmb 'Error Fatal'
	
	test 'With garbage in level list', ->
		assert.ok L = new AbstractLogger levels: { '': 'Trace', 'foo.bar': ['error', 'notexistinglevel', 'DEBUG'] }
		L.levelConfig.should.eql
			'': cmb 'Trace Debug Info Warn Error Fatal'
			'foo.bar': cmb 'Error Debug'
	
	test 'With garbage as level', ->
		assert.ok L = new AbstractLogger levels: { '': 'Trace', 'foo.bar': 'notexistinglevel' }
		L.levelConfig.should.eql
			'': cmb 'Trace Debug Info Warn Error Fatal'
		L.levelConfig.should.not.have.property 'foo.bar'
	
	test 'With special level OFF', ->
		assert.ok L = new AbstractLogger levels: { '': 'Trace', 'foo.bar': 'OFF', 'test': 'off' }
		L.levelConfig.should.eql
			'': cmb 'Trace Debug Info Warn Error Fatal'
			'foo.bar': 0
			'test': 0
	
	test 'With special level ALL', ->
		assert.ok L = new AbstractLogger levels: { '': 'Trace', 'foo.bar': 'ALL', 'test': 'all' }
		L.levelConfig.should.eql
			'': cmb 'Trace Debug Info Warn Error Fatal'
			'foo.bar': cmb 'Trace Debug Info Warn Error Fatal'
			'test': cmb 'Trace Debug Info Warn Error Fatal'
	
	test 'With min', ->
		assert.ok L = new AbstractLogger min: 'INFO', levels: { '': 'ALL', 'foo.bar': 'ERROR', 'test': 'INFO', 'bar': ['FATAL', 'DEBUG', 'INFO'] }
		L.levelConfig.should.eql
			'': cmb 'Info Warn Error Fatal'
			'foo.bar': cmb 'Error Fatal'
			'test': cmb 'Info Warn Error Fatal'
			'bar': cmb 'Info Fatal'
	
	test 'With max', ->
		assert.ok L = new AbstractLogger max: 'info', levels: { '': 'ALL', 'foo.bar': 'ERROR', 'test': 'INFO', 'bar': ['WARN', 'DEBUG', 'INFO'] }
		L.levelConfig.should.eql
			'': cmb 'Trace Debug Info'
			'foo.bar': 0
			'test': cmb 'Info'
			'bar': cmb 'Debug Info'
	
	test 'With min and max', ->
		assert.ok L = new AbstractLogger min: 'Debug', max: 'WARN', levels: { '': 'ALL', 'foo.bar': 'ERROR', 'test': 'Info', 'bar': ['DEBUG', 'FATAL', 'INFO', 'Trace'] }
		L.levelConfig.should.eql
			'': cmb 'Debug Info Warn'
			'foo.bar': 0
			'test': cmb 'Info Warn'
			'bar': cmb 'Debug Info'
	
	test 'With min and max having min > max', ->
		assert.ok L = new AbstractLogger min: 'Warn', max: 'DEBUG', levels: { '': 'ALL', 'foo.bar': 'ERROR', 'test': 'Info', 'bar': ['DEBUG', 'FATAL', 'INFO', 'Trace'] }
		L.levelConfig.should.eql
			'': cmb 'Debug Info Warn'
			'foo.bar': 0
			'test': cmb 'Info Warn'
			'bar': cmb 'Debug Info'
	
	for name in [ 'formatPattern', 'format', 'pattern' ] then do (name) ->
		test "Spec with sole #{name}", ->
			act = {}
			act[name] = "[#{name}] %Y"
			
			assert.ok L = new AbstractLogger act
			L.formatPattern.should.equal "[#{name}] %Y"
	
	test 'Special log formats', ->
		assert.ok L = new AbstractLogger formatPattern: '_%{DATE}-%{GARBAGE}_%{}-%{_%}-%Y_%{NOT ALLOWED}-%{DATETIME}_%{TIME}%{DATETIME_ISO8601}'
		L.formatPattern.should.equal '_%Y-%M-%D-_-%{_%}-%Y_%{NOT ALLOWED}-%Y-%M-%D %H:%i:%s.%S_%H:%i:%s.%S%Y-%M-%DT%H:%i:%s.%S'
	


suite 'AbstractLogger.getLevelConfig', ->
	
	AbstractLogger = LogLevels = null
	
	setup ->
		AbstractLogger = require "../../loggers/AbstractLogger"
		LogLevels = require "../../util/LogLevels"
	
	
	testLevelConfig = (returnValue, parts..., levels) -> 
		assert.ok L = new AbstractLogger levels: levels
		assert.equal L.getLevelConfig(parts), LogLevels.combineLevels returnValue.split(/\s+/)...
	
	
	test 'Single part no match', -> testLevelConfig 'Error Fatal', 'foo', 'bar', '': 'ERROR', 'abc.test': 'INFO'
	
	test 'Single part under-match', -> testLevelConfig 'Error Fatal', 'foo', 'bar', '': 'ERROR', 'foo.bar.test': 'INFO'
	
	test 'Single part exact match', -> testLevelConfig 'Info Warn Error Fatal', 'foo', 'bar', '': 'ERROR', 'foo.bar': 'INFO'
	
	test 'Single part over-match', -> testLevelConfig 'Info Warn Error Fatal', 'foo', 'bar', '': 'ERROR', 'foo': 'INFO'
	
	test 'Invalid internal level config', ->
		assert.ok L = new AbstractLogger()
		assert.ok L.levelConfig
		L.levelConfig = {}
		
		(-> L.getLevelConfig ['foo', 'bar']).should.throwError 'Invalid internal level config'
	


suite 'AbstractLogger.logMessage', ->
	
	AbstractLogger = null
	
	setup -> AbstractLogger = require "../../loggers/AbstractLogger"
	
	
	testLogMessage = (fmt, result) -> 
		assert.ok L = new AbstractLogger formatPattern: fmt, levels: { '': 'ALL' }
		firstcall = yes
		L.log = (msg) ->
			assert.ok firstcall
			firstcall = no
			arguments.length.should.equal 1
			assert.equal msg, result
		
		L.logMessage
			level: 'Info'
			msg: 'My test message.'
			name:  'foo.bar.abc.TestComponent'
			parts: ['foo', 'bar', 'abc', 'TestComponent']
			date: new Date '2013-11-02 17:00:22.082'
	
	
	test 'No format flags', -> testLogMessage 'Foo', 'Foo'
	
	test 'Invalid format flag', -> testLogMessage 'Foo %Q bar %090Q abc % %-Y test', 'Foo  bar  abc % %-Y test'
	
	test 'With format flags', ->
		testLogMessage(
			'%%Y %%%Y %6Y %1Y %M %3M %D %0D - %H %i %0i %s %S %4S %2S %1S - %T %15T - %L [%6L] - %n: %m',
			'%Y %2013 002013 2013 11 011 02 2 - 17 00 0 22 082 0082 82 82 - 1383408022082 001383408022082 - INFO  [INFO  ] - foo.bar.abc.TestComponent: My test message.'
		)
	
	test 'Name parts format', ->
		testLogMessage(
			'%4n - %3n - %2n - %1n - %0n - %n'
			[
				'foo.bar.abc.TestComponent'
				'foo.bar.abc.TestComponent'
				'bar.abc.TestComponent'
				'abc.TestComponent'
				'TestComponent'
				'foo.bar.abc.TestComponent'
			].join ' - '
		)
