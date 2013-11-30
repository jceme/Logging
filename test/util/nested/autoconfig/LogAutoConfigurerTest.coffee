require 'should'
assert = require 'assert'
fs = require 'fs'
path = require 'path'


LogAutoConfigurer = null
ConsoleLogger = null

withConfig = (name, content, fn) ->
	p = path.resolve __dirname, name
	fs.existsSync(p).should.not.be.ok
	fs.writeFileSync p, content
	try do fn
	finally fs.unlinkSync p


test 'Require ok', ->
	fn = ->
		LogAutoConfigurer = require '../../../../util/LogAutoConfigurer'
		ConsoleLogger = require '../../../../loggers/ConsoleLogger'
	
	fn.should.not.throwError()

test 'Loaded', ->
	LogAutoConfigurer.should.be.ok
	ConsoleLogger.should.be.ok



suite 'findAndConfigureLogging', ->
	
	isDefaultLogger = (logger) ->
		assert.ok logger
		logger.should.be.instanceOf ConsoleLogger
	
	
	test 'no name', -> isDefaultLogger LogAutoConfigurer.findAndConfigureLogging()
	
	test 'not existing name', -> isDefaultLogger LogAutoConfigurer.findAndConfigureLogging '__never_existing_name__'
	
	test 'local dir name', -> isDefaultLogger LogAutoConfigurer.findAndConfigureLogging __dirname
	
	test 'global dir name', -> isDefaultLogger LogAutoConfigurer.findAndConfigureLogging 'node_modules'
	
	test 'local config', ->
		withConfig 'myconfig.json', '', -> isDefaultLogger LogAutoConfigurer.findAndConfigureLogging 'js/test/util/nested/autoconfig/myconfig.json'
	
	test 'global config', ->
		withConfig 'myconfig.json', '{}', -> isDefaultLogger LogAutoConfigurer.findAndConfigureLogging path.resolve __dirname, 'myconfig.json'
	
	test 'not existing logger', ->
		withConfig 'myconfig.json', '{loggers:[{type:"NotExistingLogger"}]}', -> assert not LogAutoConfigurer.findAndConfigureLogging 'js/test/util/nested/autoconfig/myconfig.json'
	
	test 'one noop logger', ->
		withConfig 'myconfig.json', '{loggers:[{type:"NoopLogger"}]}', ->
			assert.ok logger = LogAutoConfigurer.findAndConfigureLogging 'js/test/util/nested/autoconfig/myconfig.json'
			logger.should.be.instanceOf require '../../../../loggers/NoopLogger'
	
	test 'two noop loggers', ->
		withConfig 'myconfig.json', '{loggers:[{type:"NoopLogger"},{type:"NoopLogger"}]}', ->
			assert.ok logger = LogAutoConfigurer.findAndConfigureLogging 'js/test/util/nested/autoconfig/myconfig.json'
			logger.should.be.instanceOf require '../../../../loggers/TeePseudoLogger'
			logger.loggers.length.should.equal 2
			logger.loggers[0].should.be.instanceOf require '../../../../loggers/NoopLogger'
			logger.loggers[1].should.be.instanceOf require '../../../../loggers/NoopLogger'
