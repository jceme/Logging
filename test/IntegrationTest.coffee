require 'should'


suite 'Integration tests', ->
	
	Log = Config = LogAutoConfigurer = LogLevels = allLevels = null
	
	setup ->
		Log = require '../Log'
		Config = require '../util/Config'
		LogAutoConfigurer = require '../util/LogAutoConfigurer'
		LogLevels = require '../util/LogLevels'
		allLevels = ( k for k of LogLevels )
	
	test 'Log with Tee and two Consoles', ->
		cfg = new Config
			type: require.resolve('./IntegrationTestLogger')
			format: '%0L - %n: %m'
			loggers: [{}, {}]
		
		Logger = LogAutoConfigurer.createLoggers cfg
		
		Log.setLogger Logger
		
		log = new Log 'foo.bar'
		for lvl in allLevels
			log[lvl.toLowerCase()] "My #{lvl} message."
		
		expected = ( "#{lvl.toUpperCase()} - foo.bar: My #{lvl} message." for lvl in "Info Warn Error Fatal".split /\s+/ )
		Logger.loggers.length.should.equal 2
		Logger.loggers[0].should.not.equal Logger.loggers[1]
		Logger.loggers[0].buffer.should.eql expected
		Logger.loggers[1].buffer.should.eql expected
