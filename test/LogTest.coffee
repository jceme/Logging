require 'should'
assert = require 'assert'
mockery = require 'mockery'
nodemock = require 'nodemock'



suite 'Log: Sanity checks', ->
	
	test "Require ok for Log", ->
		require('../Log').should.be.type 'function'



suite 'Log init', ->
	
	LogLevels = require '../util/LogLevels'
	Log = _cnf = mocks = null
	
	allLevels = ( v for _, v of LogLevels ).reduce ((p, c) -> p | c), 0
	
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
		Log = require '../Log'
	
	teardown ->
		do mock.assertThrows for mock in mocks
		mocks = null
		do mockery.deregisterAll
		do mockery.resetCache
	
	
	test 'Simple init', ->
		return
	
	test 'Simple init auto config', ->
		logger = mkmock('getLevelConfig').takes(['abc', 'xyz']).returns(allLevels)
		logger.mock('logMessage').fail()
		_cnf.mock('findAndConfigureLogging').takes('logconf.json').returns(logger)
		
		assert.ok log = new Log 'abc.xyz'
	
	[ null, 'foolog.json' ].forEach (confname) ->
		[ 'throwing error', 'returning null', 'returning logger' ].forEach (resultOption) ->
			test "Init explicitly with #{confname} #{resultOption}", ->
				expname = confname ? 'logconf.json'
				SL = -> if confname then Log.setLogger confname else do Log.setLogger
				
				switch resultOption
					when 'throwing error'
						cnt = 0
						_cnf.findAndConfigureLogging = (name) ->
							arguments.length.should.equal 1
							name.should.equal expname
							cnt++
							throw new Error 'Cannot find logging'
						
						(-> do SL).should.throwError 'Cannot find logging'
						cnt.should.equal 1
					
					when 'returning null'
						_cnf.mock('findAndConfigureLogging').takes(expname).returns(null)
						
						(-> do SL).should.throwError 'Logger not usable'
					
					else
						logger = mkmock('getLevelConfig').fail().mock('logMessage').fail()
						_cnf.mock('findAndConfigureLogging').takes(expname).returns(logger)
						
						do SL
	
	test 'Logger found is unusable', ->
		logger = {}
		_cnf.mock('findAndConfigureLogging').takes('foo.json').returns(logger)
		
		logger = mkmock('getLevelConfig').fail()
		_cnf.mock('findAndConfigureLogging').takes('bar.json').returns(logger)
		
		logger = mkmock('logMessage').fail()
		_cnf.mock('findAndConfigureLogging').takes('test.json').returns(logger)
		
		logger = mkmock('getLevelConfig').fail().mock('logMessage').fail()
		_cnf.mock('findAndConfigureLogging').takes('ok.json').returns(logger)
		
		(-> Log.setLogger 'foo.json').should.throwError 'Logger not usable'
		(-> Log.setLogger 'bar.json').should.throwError 'Logger not usable'
		(-> Log.setLogger 'test.json').should.throwError 'Logger not usable'
		Log.setLogger 'ok.json'
	
	test 'Logger set is unusable', ->
		logger1 = {}
		logger2 = mkmock('getLevelConfig').fail()
		logger3 = mkmock('logMessage').fail()
		logger4 = mkmock('getLevelConfig').fail().mock('logMessage').fail()
		
		(-> Log.setLogger logger1).should.throwError 'Logger not usable'
		(-> Log.setLogger logger2).should.throwError 'Logger not usable'
		(-> Log.setLogger logger3).should.throwError 'Logger not usable'
		Log.setLogger logger4
	
	test 'Logger set correctly and persistent in Logs', ->
		logger1 = mkmock('getLevelConfig').takes(['abc']).returns(allLevels)
		logger1.mock('getLevelConfig').takes(['xyz']).returns(allLevels)
		logger1.logMessage = (obj) -> (@msgs ?= []).push obj.msg
		
		logger2 = mkmock('getLevelConfig').takes(['test']).returns(allLevels)
		logger2.logMessage = logger1.logMessage
		
		Log.setLogger logger1
		log1 = new Log 'abc'
		log1.debug 'My abc msg'
		
		(-> Log.setLogger {}).should.throwError 'Logger not usable'
		log2 = new Log 'xyz'
		log2.debug 'My xyz msg'
		
		Log.setLogger logger2
		log3 = new Log 'test'
		log3.debug 'My test msg'
		
		log1.debug 'Other abc msg'
		log2.debug 'Other xyz msg'
		
		logger1.msgs.should.eql ['My abc msg', 'My xyz msg', 'Other abc msg', 'Other xyz msg']
		logger2.msgs.should.eql ['My test msg']



suite 'Log constructor and logging', ->
	
	LogLevels = require '../util/LogLevels'
	Log = logger = mocks = null
	
	allLevels = ( v for _, v of LogLevels ).reduce ((p, c) -> p | c), 0
	
	mkmock = (fnname) ->
		m = nodemock.mock fnname
		mocks.push m
		m
	
	
	suiteSetup -> mockery.enable useCleanCache: yes
	
	suiteTeardown -> do mockery.disable
	
	setup ->
		mocks = []
		mockery.registerAllowables [
			'../Log'
			'./util/LogLevels'
		]
		Log = require '../Log'
		
		logger = mkmock('getLevelConfig').fail().mock('logMessage').fail()
		Log.setLogger logger
		logger.reset()
	
	teardown ->
		do mock.assertThrows for mock in mocks
		mocks = null
		do mockery.deregisterAll
		do mockery.resetCache
	
	
	levelConfig = (parts, result = allLevels) ->
		logger.mock('getLevelConfig').takes(parts).returns(result)
	
	cnfLogger = (loggerspec = {}) ->
		cnf = loggerspec.getLevelConfig ? {}
		logger = mkmock('getLevelConfig').takes(cnf.args ? ['abc', 'xyz']).returns (
			if cnf.result? then cnf.result.map((x) -> LogLevels[x])
			else ( v for _, v of LogLevels )
		).reduce ((p, c) -> p | c), 0
		
		cnf = loggerspec.logMessage ? {}
		logger = logger.mock('logMessage')
		logger = logger.takes(cnf.args) if cnf.args?
		
		_cnf.mock('findAndConfigureLogging').takes(loggerspec.conf ? 'logconf.json').returns(logger)
	
	
	test 'Log name', ->
		(-> new Log()).should.throwError 'Logger name required'
		(-> new Log '').should.throwError 'Logger name required'
		(-> new Log 15).should.throwError 'Logger name required'
		
		(-> new Log '.abc').should.throwError 'Invalid logger name: .abc'
		(-> new Log 'abc.').should.throwError 'Invalid logger name: abc.'
		(-> new Log '.abc.').should.throwError 'Invalid logger name: .abc.'
		(-> new Log 'abc..xyz').should.throwError 'Invalid logger name: abc..xyz'
		
		levelConfig ['abc', 'xyz']
		new Log('  abc.xyz    ').name.should.equal 'abc.xyz'
		
		levelConfig ['abc']
		(L = new Log('abc')).name.should.equal 'abc'
		L.name = 'other'
		L.name.should.equal 'abc'
	
	loglevels = ( n for n of LogLevels )
	loglevels.forEach (level) ->
		test "Sole #{level} logging", ->
			cnt = 0
			levelConfig ['abc', 'xyz'], LogLevels[level]
			logger.logMessage = (obj) ->
				arguments.length.should.equal 1
				obj.should.have.property 'level', level
				obj.should.have.property 'msg', 'My test message'
				obj.should.have.property 'name', 'abc.xyz'
				obj.should.have.properties 'parts', 'date'
				obj.parts.should.eql ['abc', 'xyz']
				obj.date.should.be.instanceOf Date
				cnt++
			
			log = new Log 'abc.xyz'
			loglevels.forEach (lvl) ->
				log["is#{lvl}"]().should.equal(lvl is level)
				log[lvl.toLowerCase()] 'My test message'
			
			cnt.should.equal 1
	
	test "Only allowed logging", ->
		levelConfig ['abc', 'xyz'], LogLevels.Debug | LogLevels.Warn
		logger.mock('logMessage').takes(level: 'Debug')
		logger.mock('logMessage').takes(level: 'Warn')
		
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
			levelConfig ['abc', 'xyz']
			logger.mock('logMessage').takes(level: 'Debug', msg: logcallresult)
			
			log = new Log 'abc.xyz'
			log.debug.apply log, logcallparams
	
	test "Log call with function result", ->
		levelConfig ['abc', 'xyz']
		logger.mock('logMessage').takes(level: 'Debug', msg: 'Function result {}')
		
		log = new Log 'abc.xyz'
		log.debug(( -> 'Function result {}' ), 14)
	
	test "Log call with asynchronous function result", (done) ->
		levelConfig ['abc', 'xyz']
		logger.mock('logMessage').takes(level: 'Debug', msg: 'Asynchronous function result')
		logger.mock('logMessage').takes(level: 'Debug', msg: 'Second asynchronous function result')
		
		log = new Log 'abc.xyz'
		log.debug (logdone) ->
			setTimeout ->
				logdone 'Asynchronous function result'
				logdone 'Second asynchronous function result'
				do done
			, 10
	
	test 'toString', ->
		levelConfig ['abc', 'xyz']
		logger.mock('logMessage').fail()
		
		log = new Log '   abc.xyz '
		log.toString().should.equal 'Logger abc.xyz'
		log.name.should.equal 'abc.xyz'
