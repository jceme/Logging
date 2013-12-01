require 'should'
assert = require 'assert'
mockery = require 'mockery'
nodemock = require 'nodemock'



suite 'Log: Sanity checks', ->
	
	test "Require ok for Log", ->
		obj = null
		fn = -> obj = require "../Log"
		fn.should.not.throwError()
		assert.ok obj



suite 'Log producer', ->
	
	LogLevels = require '../util/LogLevels'
	_cnf = mocks = null
	
	mkmock = (fnname) ->
		m = nodemock.mock fnname
		mocks.push m
		m
	
	
	suiteSetup -> mockery.enable useCleanCache: yes
	
	suiteTeardown -> do mockery.disable
	
	setup ->
		mocks = []
		mockery.registerMock './util/LogAutoConfigurer', _cnf = mkmock('__noop').fail()
		mockery.registerAllowables [
			'../Log'
			'./util/LogLevels'
		]
	
	teardown ->
		do mock.assertThrows for mock in mocks
		mocks = null
		do mockery.deregisterAll
		do mockery.resetCache
	
	
	test 'Simple init', ->
		logger =
			getLevelConfig: -> assert no
			logMessage: -> assert no
		
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		
		require '../Log'
	
	test 'Simple init null logger', ->
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(null)
		
		(-> require '../Log').should.throwError 'Logger not usable'
	
	test 'Simple init fails finding logger', ->
		_cnf.findAndConfigureLogging = (n, c) ->
			arguments.length.should.equal 2
			n.should.equal 'logconf.json'
			c.should.equal on
			throw new Error 'Cannot find any logger'
		
		(-> require '../Log').should.throwError 'Cannot find any logger'
	
	test 'Simple init incomplete logger', ->
		logger = {}
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		(-> require '../Log').should.throwError 'Logger not usable'
		do mockery.resetCache
		
		logger =
			getLevelConfig: -> assert no
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		(-> require '../Log').should.throwError 'Logger not usable'
		do mockery.resetCache
		
		logger =
			logMessage: -> assert no
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		(-> require '../Log').should.throwError 'Logger not usable'
		do mockery.resetCache
		
		logger =
			getLevelConfig: -> assert no
			logMessage: -> assert no
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		require '../Log'
	
	test 'Simple init with file name', ->
		logger =
			getLevelConfig: -> assert no
			logMessage: -> assert no
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		
		Log = require '../Log'
		
		logger =
			getLevelConfig: -> assert no
			logMessage: -> assert no
		_cnf.mock('findAndConfigureLogging').takes('foo.json', on).returns(logger)
		
		Log.initLogging 'foo.json'
	
	test 'Simple init with file name failing', ->
		logger =
			getLevelConfig: -> assert no
			logMessage: -> assert no
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		
		Log = require '../Log'
		
		_cnf.findAndConfigureLogging = (n, c) ->
			arguments.length.should.equal 2
			n.should.equal 'foo.json'
			c.should.equal on
			throw new Error 'Cannot find any logger'
		
		(-> Log.initLogging 'foo.json').should.throwError 'Cannot find any logger'
	
	test 'Log name', ->
		logger =
			getLevelConfig: -> 0
			logMessage: -> assert no
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		
		Log = require '../Log'
		
		(-> new Log()).should.throwError 'Logger name required'
		(-> new Log '').should.throwError 'Logger name required'
		(-> new Log 15).should.throwError 'Logger name required'
		
		(-> new Log '.abc').should.throwError 'Invalid logger name: .abc'
		(-> new Log 'abc.').should.throwError 'Invalid logger name: abc.'
		(-> new Log '.abc.').should.throwError 'Invalid logger name: .abc.'
		(-> new Log 'abc..xyz').should.throwError 'Invalid logger name: abc..xyz'
		
		new Log('  abc.xyz    ').name.should.equal 'abc.xyz'
		(L = new Log('abc')).name.should.equal 'abc'
		L.name = 'other'
		L.name.should.equal 'abc'
	
	test 'Simple init with file name failing silently', ->
		c1 = c2 = 0
		logger =
			getLevelConfig: (parts) ->
				arguments.length.should.equal 1
				parts.should.eql ['abc', 'xyz']
				c1++
				LogLevels.Debug
			
			logMessage: (obj) ->
				arguments.length.should.equal 1
				obj.msg.should.equal 'My test message'
				c2++
		
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		Log = require '../Log'
		
		_cnf.mock('findAndConfigureLogging').takes('foo.json', on).returns(null)
		(-> Log.initLogging 'foo.json').should.throwError 'Logger not usable'
		
		# Test if old logger still used
		log = new Log 'abc.xyz'
		log.debug 'My test message'
		c1.should.equal 1
		c2.should.equal 1
	
	loglevels = ( n for n of LogLevels )
	loglevels.forEach (level) ->
		test "Sole #{level} logging", ->
			c1 = c2 = 0
			logger =
				getLevelConfig: (parts) ->
					arguments.length.should.equal 1
					parts.should.eql ['abc', 'xyz']
					c1++
					LogLevels[level]
				
				logMessage: (obj) ->
					arguments.length.should.equal 1
					obj.should.have.property 'level', level
					obj.should.have.property 'msg', 'My test message'
					obj.should.have.property 'name', 'abc.xyz'
					obj.should.have.properties 'parts', 'date'
					obj.parts.should.eql ['abc', 'xyz']
					obj.date.should.be.instanceOf Date
					c2++
			
			_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
			
			Log = require '../Log'
			log = new Log 'abc.xyz'
			
			loglevels.forEach (lvl) ->
				log["is#{lvl}"]().should.equal(lvl is level)
				log[lvl.toLowerCase()] 'My test message'
			
			c1.should.equal 1
			c2.should.equal 1
	
	test "Only allowed logging", ->
		logger = mkmock('getLevelConfig').takes(['abc', 'xyz']).returns(LogLevels.Debug | LogLevels.Warn)
		logger.mock('logMessage').takes(level: 'Debug')
		logger.mock('logMessage').takes(level: 'Warn')
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		
		Log = require '../Log'
		log = new Log 'abc.xyz'
		
		for lvl of LogLevels
			log["is#{lvl}"]().should.equal(lvl in ['Debug', 'Warn'])
			log[lvl.toLowerCase()] 'My test message'
	
	logcall =
		'Simple msg without params': ['Simple msg without params']
		'Simple msg with idx params 17 and foo': ['Simple msg with idx params {} and {}', 17, 'foo']
		'Simple msg with named params foo and 17 and foo': ['Simple msg with named params {1} and {0} and {1}', 17, 'foo']
		'Simple msg with mixed params 2 and 1 and 4 and 2': ['Simple msg with mixed params {1} and {} and {3} and {}', 1, 2, 3, 4, 5]
	
	for logcallresult, logcallparams of logcall
		test "Log call with #{logcallparams}", ->
			logger = mkmock('getLevelConfig').takes(['abc', 'xyz']).returns(LogLevels.Debug)
			logger.mock('logMessage').takes(level: 'Debug', msg: logcallresult)
			_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
			
			Log = require '../Log'
			log = new Log 'abc.xyz'
			log.debug.apply log, logcallparams
	
	test "Log call with function result", ->
		logger = mkmock('getLevelConfig').takes(['abc', 'xyz']).returns(LogLevels.Debug)
		logger.mock('logMessage').takes(level: 'Debug', msg: 'Function result {}')
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		
		Log = require '../Log'
		log = new Log 'abc.xyz'
		log.debug(( -> 'Function result {}' ), 14)
	
	test "Log call with asynchronous function result", (done) ->
		logger = mkmock('getLevelConfig').takes(['abc', 'xyz']).returns(LogLevels.Debug)
		logger.mock('logMessage').takes(level: 'Debug', msg: 'Asynchronous function result')
		_cnf.mock('findAndConfigureLogging').takes('logconf.json', on).returns(logger)
		
		Log = require '../Log'
		log = new Log 'abc.xyz'
		log.debug (logdone) -> setTimeout (-> logdone 'Asynchronous function result'; done()), 10
