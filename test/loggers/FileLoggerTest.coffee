require 'should'
assert = require 'assert'
mockery = require 'mockery'
nodemock = require 'nodemock'



suite 'FileLogger: Sanity checks', ->
	
	test "Require ok for loggers/FileLogger", ->
		obj = null
		fn = -> obj = require "../../loggers/FileLogger"
		fn.should.not.throwError()
		assert.ok obj



suite 'FileLogger', ->
	
	FileLogger = _fs = _path = mocks = null
	
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
			'../../loggers/FileLogger'
			'./AbstractLogger'
			'../util/LogLevels'
		]
		FileLogger = require '../../loggers/FileLogger'
	
	teardown ->
		FileLogger.closeAllOpenFiles on
		
		do mock.assertThrows for mock in mocks
		mocks = null
		do mockery.deregisterAll
		do mockery.resetCache
	
	
	test 'No opts', ->
		_path.mock('resolve').takes('logging.log').returns('/foo/bar/logging.log')
		_fs.mock('openSync').takes('/foo/bar/logging.log', 'a', 0o644).returns(82)
		
		assert.ok L = new FileLogger()
		L.fd.should.equal 82
		
		_fs.mock('closeSync').takes(82)
	
	test 'With file name, append, mode', ->
		_path.mock('resolve').takes('log.log').returns('/foo/bar/log.log')
		_fs.mock('openSync').takes('/foo/bar/log.log', 'w', 0o664).returns(7)
		
		assert.ok L = new FileLogger file: 'log.log', filename: 'foo.log', append: no, mode: 0o664
		L.fd.should.equal 7
		
		_fs.mock('closeSync').takes(7)
	
	test 'With file name, custom open flags', ->
		_path.mock('resolve').takes('log.log').returns('/foo/bar/log.log')
		_fs.mock('openSync').takes('/foo/bar/log.log', 'xyz', 0o644).returns(7)
		
		assert.ok L = new FileLogger file: 'log.log', filename: 'foo.log', openFlags: 'xyz', flags: 'abc'
		L.fd.should.equal 7
		
		_fs.mock('closeSync').takes(7)
	
	test 'With file name, overwrite, cached', ->
		_path.mock('resolve').takes('log.log').returns('/foo/bar/log.log').times(2)
		_fs.mock('openSync').takes('/foo/bar/log.log', 'w', 0o644).returns(15).times(1)
		
		assert.ok L1 = new FileLogger file: 'log.log', filename: 'foo.log', overwrite: yes, append: yes
		L1.fd.should.equal 15
		
		assert.ok L2 = new FileLogger file: 'log.log', filename: 'foo.log', overwrite: no
		L2.fd.should.equal 15
		
		_fs.mock('closeSync').takes(15)
	
	test 'Open fails', ->
		_path.mock('resolve').takes('logging.log').returns('/foo/bar/logging.log')
		_fs.openSync = (n, f, m) ->
			arguments.length.should.equal 3
			n.should.equal '/foo/bar/logging.log'
			f.should.equal 'a'
			m.should.equal 0o644
			throw new Error 'Cannot open file: /foo/bar/logging.log'
		
		(-> new FileLogger()).should.throwError 'Cannot open file: /foo/bar/logging.log'
	
	test 'Close fails', ->
		_path.mock('resolve').takes('logging.log').returns('/foo/bar/logging.log')
		_path.mock('resolve').takes('foo.log').returns('/foo/bar/foo.log')
		_fs.mock('openSync').takes('/foo/bar/logging.log', 'a', 0o644).returns(51)
		_fs.mock('openSync').takes('/foo/bar/foo.log', 'a', 0o644).returns(69)
		
		assert.ok L1 = new FileLogger()
		L1.fd.should.equal 51
		
		assert.ok L1 = new FileLogger filename: 'foo.log'
		L1.fd.should.equal 69

		closed = []
		failed = 0
		_fs.closeSync = (fd) ->
			arguments.length.should.equal 1
			switch fd
				when 51
					closed.length.should.equal 0
					failed.should.equal 0
					failed++
					throw new Error 'Cannot close file: /foo/bar/logging.log'
				else
					closed.push fd
		
		do FileLogger.closeAllOpenFiles
		closed.should.eql [69]
		failed.should.equal 1
		
		delete _fs.closeSync
	
	test 'Logging', ->
		_path.mock('resolve').takes('foo.log').returns('/foo/bar/foo.log')
		_fs.mock('openSync').takes('/foo/bar/foo.log', 'a', 0o644).returns(82)
		
		assert.ok L = new FileLogger file: 'foo.log', on
		L.fd.should.equal 82
		
		_fs.mock('writeSync').takes(82, "\n")
		L.log ""
		
		_fs.mock('writeSync').takes(82, "This is a %Y log message.\n")
		L.log "This is a %Y log message."
		
		_fs.mock('writeSync').takes(82, "This is a log message.\nJust for you.\n\n")
		L.log "This is a log message.\nJust for you.\n"
		
		_fs.mock('closeSync').takes(82)
	
	test 'Logging fails writing', ->
		_path.mock('resolve').takes('foo.log').returns('/foo/bar/foo.log')
		_fs.mock('openSync').takes('/foo/bar/foo.log', 'a', 0o644).returns(82)
		
		assert.ok L = new FileLogger file: 'foo.log', on
		L.fd.should.equal 82
		
		failed = 0
		_fs.writeSync = (fd, msg) ->
			arguments.length.should.equal 2
			fd.should.equal 82
			msg.should.equal "\n"
			failed++
			throw new Error 'Failed write'
		
		(-> L.log '').should.throwError 'Failed write'
		failed.should.equal 1
		
		_fs.mock('closeSync').takes(82)
	
	test 'Logging fails writing silent', ->
		_path.mock('resolve').takes('foo.log').returns('/foo/bar/foo.log')
		_fs.mock('openSync').takes('/foo/bar/foo.log', 'a', 0o644).returns(82)
		
		assert.ok L = new FileLogger file: 'foo.log'
		L.fd.should.equal 82
		
		failed = 0
		_fs.writeSync = (fd, msg) ->
			arguments.length.should.equal 2
			fd.should.equal 82
			msg.should.equal "\n"
			failed++
			throw new Error 'Failed write'
		
		L.log ''
		failed.should.equal 1
		
		_fs.mock('closeSync').takes(82)
