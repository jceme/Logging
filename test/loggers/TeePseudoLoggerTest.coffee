require 'should'
nodemock = require 'nodemock'

LogLevels = require '../../util/LogLevels'
TeePseudoLogger = require '../../loggers/TeePseudoLogger'



suite 'TeePseudoLogger class', ->
	
	mocks = null
	
	mkmock = (fnname) ->
		m = nodemock.mock fnname
		mocks.push m
		m
	
	
	setup ->
		mocks = []
	
	teardown ->
		do mock.assertThrows for mock in mocks
		mocks = null
	
	
	test 'Empty constructor', ->
		logger = new TeePseudoLogger()
		logger.getLevelConfig(['foo']).should.eql mask: 0, extra: []
		logger.logMessage {}
		logger.toString().should.be.ok
	
	test 'One logger saving extra', ->
		l1 = mkmock('getLevelConfig').takes(['foo']).returns(extra: 27, mask: LogLevels.Debug)
		
		logger = new TeePseudoLogger [l1]
		
		extra = [{ mask: LogLevels.Debug, extra: 27 }]
		logger.getLevelConfig(['foo']).should.eql mask: LogLevels.Debug, extra: extra
		
		l1.mock('logMessage').takes(level: 'Debug', numLevel: LogLevels.Debug, extra: 27, msg: 'My debug msg')
		
		logger.logMessage level: 'Warn', numLevel: LogLevels.Warn, msg: 'My warn msg', extra: extra
		logger.logMessage level: 'Debug', numLevel: LogLevels.Debug, msg: 'My debug msg', extra: extra
		extra.should.eql [{ mask: LogLevels.Debug, extra: 27 }]
	
	test 'Two loggers on separate levels', ->
		l1 = mkmock('getLevelConfig').takes(['foo']).returns(extra: 27, mask: LogLevels.Debug)
		l2 = mkmock('getLevelConfig').takes(['foo']).returns(extra: ['bar', 8], mask: LogLevels.Warn)
		
		logger = new TeePseudoLogger [l1, l2]
		
		extra = [
			{ mask: LogLevels.Debug, extra: 27 }
			{ mask: LogLevels.Warn,  extra: ['bar', 8] }
		]
		logger.getLevelConfig(['foo']).should.eql extra: extra, mask: LogLevels.combineLevels 'Debug', 'Warn'
		
		l1.mock('logMessage').takes(level: 'Debug', numLevel: LogLevels.Debug, extra: 27, msg: 'My debug msg')
		l2.mock('logMessage').takes(level: 'Warn', numLevel: LogLevels.Warn, extra: ['bar', 8], msg: 'My warn msg')
		
		logger.logMessage level: 'Warn', numLevel: LogLevels.Warn, msg: 'My warn msg', extra: extra
		logger.logMessage level: 'Info', numLevel: LogLevels.Info, msg: 'My info msg', extra: extra
		logger.logMessage level: 'Debug', numLevel: LogLevels.Debug, msg: 'My debug msg', extra: extra
		extra.should.eql [
			{ mask: LogLevels.Debug, extra: 27 }
			{ mask: LogLevels.Warn,  extra: ['bar', 8] }
		]
	
	test 'Two loggers with common levels', ->
		l1 = mkmock('getLevelConfig').takes(['foo']).returns(extra: 27, mask: LogLevels.combineLevels 'Debug', 'Warn')
		l2 = mkmock('getLevelConfig').takes(['foo']).returns(extra: ['bar', 8], mask: LogLevels.Warn)
		
		logger = new TeePseudoLogger [l1, l2]
		
		extra = [
			{ extra: 27, mask: LogLevels.combineLevels 'Debug', 'Warn' }
			{ mask: LogLevels.Warn,  extra: ['bar', 8] }
		]
		logger.getLevelConfig(['foo']).should.eql extra: extra, mask: LogLevels.combineLevels 'Debug', 'Warn'
		
		l1.mock('logMessage').takes(level: 'Debug', extra: 27, msg: 'My debug msg')
		l1.mock('logMessage').takes(level: 'Warn', extra: 27, msg: 'My warn msg')
		l2.mock('logMessage').takes(level: 'Warn', extra: ['bar', 8], msg: 'My warn msg')
		
		logger.logMessage level: 'Warn', numLevel: LogLevels.Warn, msg: 'My warn msg', extra: extra
		logger.logMessage level: 'Info', numLevel: LogLevels.Info, msg: 'My info msg', extra: extra
		logger.logMessage level: 'Debug', numLevel: LogLevels.Debug, msg: 'My debug msg', extra: extra
	
	test 'Nested TeePseudoLoggers', ->
		l1 = mkmock('getLevelConfig').takes(['foo']).returns(extra: 27, mask: LogLevels.Debug)
		l2 = mkmock('getLevelConfig').takes(['foo']).returns(extra: ['bar', 8], mask: LogLevels.Warn)
		
		logger1 = new TeePseudoLogger [l1, new TeePseudoLogger()]
		logger = new TeePseudoLogger [logger1, l2]
		
		extra = [
			{
				mask: LogLevels.Debug
				extra: [
					{ mask: LogLevels.Debug, extra: 27 }
					{ mask: 0, extra: [] }
				]
			}
			{ mask: LogLevels.Warn,  extra: ['bar', 8] }
		]
		logger.getLevelConfig(['foo']).should.eql extra: extra, mask: LogLevels.combineLevels 'Debug', 'Warn'
		
		l1.mock('logMessage').takes(level: 'Debug', numLevel: LogLevels.Debug, extra: 27, msg: 'My debug msg')
		l2.mock('logMessage').takes(level: 'Warn', numLevel: LogLevels.Warn, extra: ['bar', 8], msg: 'My warn msg')
		
		logger.logMessage level: 'Warn', numLevel: LogLevels.Warn, msg: 'My warn msg', extra: extra
		logger.logMessage level: 'Info', numLevel: LogLevels.Info, msg: 'My info msg', extra: extra
		logger.logMessage level: 'Debug', numLevel: LogLevels.Debug, msg: 'My debug msg', extra: extra
