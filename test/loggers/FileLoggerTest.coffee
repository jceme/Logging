require 'should'
assert = require 'assert'
mockery = require 'mockery'
nodemock = require 'nodemock'



suite 'FileLogger: Sanity checks', ->
	
	test "Require ok for loggers/FileLogger", ->
		FileLogger = null
		fn = -> FileLogger = require "../../loggers/FileLogger"
		fn.should.not.throwError()
		FileLogger.should.be.type 'function'



suite 'FileLogger methods', ->
	
	FileLogger = Config = _fs = _path = _mkdir = mocks = null
	
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
		mockery.registerMock 'mkdirp', _mkdir = mkmock('__noop').fail()
		mockery.registerAllowables [
			'../../loggers/FileLogger'
			'./AbstractLogger'
			'../util/LogLevels'
			'../util/Config'
			'../../util/Config'
		]
		FileLogger = require '../../loggers/FileLogger'
		FileLogger._maskMode = (mode) -> mode & (~0o002)
		Config = require '../../util/Config'
	
	teardown ->
		FileLogger.closeAllOpenFiles on
		
		do mock.assertThrows for mock in mocks
		mocks = null
		do mockery.deregisterAll
		do mockery.resetCache
	
	
	test 'Masking', ->
		FileLogger._getModes().should.eql [0o644, 0o755]
		FileLogger._getModes(0o644).should.eql [0o644, 0o755]
		FileLogger._getModes(0o2740).should.eql [0o2740, 0o2750]
	
	test 'Default config', ->
		_path.mock('resolve').takes('.', 'logging.log').returns('/foo/bar/logging.log')
		_path.mock('dirname').takes('/foo/bar/logging.log').returns('/foo/bar')
		_mkdir.mock('sync').takes('/foo/bar', 0o755)
		_fs.mock('existsSync').takes('/foo/bar').returns(no)
		_fs.mock('openSync').takes('/foo/bar/logging.log', 'a', 0o644).returns(82)
		
		assert.ok L = new FileLogger new Config()
		L.toString().should.equal 'FileLogger[logging.log]'
		
		_fs.mock('closeSync').takes(82)
	
	test 'Default config, dir exists', ->
		_path.mock('resolve').takes('.', 'logging.log').returns('/foo/bar/logging.log')
		_path.mock('dirname').takes('/foo/bar/logging.log').returns('/foo/bar')
		_fs.mock('existsSync').takes('/foo/bar').returns(yes)
		_fs.mock('openSync').takes('/foo/bar/logging.log', 'a', 0o644).returns(82)
		
		assert.ok L = new FileLogger new Config()
		L.toString().should.equal 'FileLogger[logging.log]'
		
		_fs.mock('closeSync').takes(82)
	
	test 'With file name, append, mode', ->
		_path.mock('resolve').takes('.', 'foo.log').returns('/foo/bar/foo.log')
		_path.mock('dirname').takes('/foo/bar/foo.log').returns('/foo/bar')
		_fs.mock('existsSync').takes('/foo/bar').returns(yes)
		_fs.mock('openSync').takes('/foo/bar/foo.log', 'w', 0o664).returns(7)
		
		assert.ok L = new FileLogger new Config file: 'log.log', filename: 'foo.log', append: no, mode: 0o664
		
		_fs.mock('closeSync').takes(7)
	
	test 'With no file name but base dir, overwrite, mode', ->
		_path.mock('resolve').takes('/foo/bar', 'logging.log').returns('/foo/bar/log.log')
		_path.mock('dirname').takes('/foo/bar/log.log').returns('/foo/bar')
		_fs.mock('existsSync').takes('/foo/bar').returns(yes)
		_fs.mock('openSync').takes('/foo/bar/log.log', 'w', 0o664).returns(7)
		
		assert.ok L = new FileLogger new Config basedir: '/foo/bar', overwrite: yes, mode: 0o664
		
		_fs.mock('closeSync').takes(7)
	
	test 'With file name, custom open flags', ->
		_path.mock('resolve').takes('..', 'log.log').returns('/foo/bar/log.log')
		_path.mock('dirname').takes('/foo/bar/log.log').returns('/foo/bar')
		_fs.mock('existsSync').takes('/foo/bar').returns(yes)
		_fs.mock('openSync').takes('/foo/bar/log.log', 'abc', 0o644).returns(7)
		
		assert.ok L = new FileLogger new Config file: 'log.log', dir: '..', flags: 'abc'
		
		_fs.mock('closeSync').takes(7)
	
	test 'With file name, overwrite, cached', ->
		debugger
		_path.mock('resolve').takes('.', 'log.log').returns('/foo/bar/log.log').times(2)
		_path.mock('dirname').takes('/foo/bar/log.log').returns('/foo/bar')
		_fs.mock('existsSync').takes('/foo/bar').returns(no)
		_fs.mock('openSync').takes('/foo/bar/log.log', 'w', 0o640).returns(15).times(1)
		_mkdir.mock('sync').takes('/foo/bar', 0o750)
		
		assert.ok L1 = new FileLogger new Config file: 'log.log', overwrite: yes, append: yes, mode: 0o640
		
		assert.ok L2 = new FileLogger new Config filename: 'log.log', overwrite: no
		
		_fs.mock('closeSync').takes(15)
	
	test 'Open fails', ->
		_path.mock('resolve').takes('.', 'logging.log').returns('/foo/bar/logging.log')
		_path.mock('dirname').takes('/foo/bar/logging.log').returns('/foo/bar')
		_fs.mock('existsSync').takes('/foo/bar').returns(yes)
		_fs.openSync = (n, f, m) ->
			arguments.length.should.equal 3
			n.should.equal '/foo/bar/logging.log'
			f.should.equal 'a'
			m.should.equal 0o644
			throw new Error 'Cannot open file: /foo/bar/logging.log'
		
		(-> new FileLogger new Config()).should.throwError 'Cannot open file: /foo/bar/logging.log'
	
	test 'Close fails', ->
		_path.mock('resolve').takes('.', 'logging.log').returns('/foo/bar/logging.log')
		_path.mock('resolve').takes('.', 'foo.log').returns('/foo/bar/foo.log')
		_path.mock('dirname').takes('/foo/bar/logging.log').returns('/foo/bar')
		_path.mock('dirname').takes('/foo/bar/foo.log').returns('/foo/bar')
		_fs.mock('existsSync').takes('/foo/bar').returns(yes).times(2)
		_fs.mock('openSync').takes('/foo/bar/logging.log', 'a', 0o644).returns(51)
		_fs.mock('openSync').takes('/foo/bar/foo.log', 'a', 0o644).returns(69)
		
		assert.ok L1 = new FileLogger new Config()
		
		assert.ok L1 = new FileLogger new Config filename: 'foo.log'

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
		_path.mock('resolve').takes('.', 'foo.log').returns('/foo/bar/foo.log')
		_fs.mock('openSync').takes('/foo/bar/foo.log', 'a', 0o644).returns(82)
		_path.mock('dirname').takes('/foo/bar/foo.log').returns('/foo/bar')
		_fs.mock('existsSync').takes('/foo/bar').returns(yes)
		
		assert.ok L = new FileLogger new Config file: 'foo.log'
		
		_fs.mock('writeSync').takes(82, "\n")
		L.log ""
		
		_fs.mock('writeSync').takes(82, "This is a %Y log message.\n")
		L.log "This is a %Y log message."
		
		_fs.mock('writeSync').takes(82, "This is a log message.\nJust for you.\n\n")
		L.log "This is a log message.\nJust for you.\n"
		
		_fs.mock('closeSync').takes(82)
	
	test 'Logging fails writing', ->
		_path.mock('resolve').takes('.', 'foo.log').returns('/foo/bar/foo.log')
		_fs.mock('openSync').takes('/foo/bar/foo.log', 'a', 0o644).returns(82)
		_path.mock('dirname').takes('/foo/bar/foo.log').returns('/foo/bar')
		_fs.mock('existsSync').takes('/foo/bar').returns(yes)
		
		assert.ok L = new FileLogger new Config file: 'foo.log', throwErrors: yes
		
		failed = 0
		_fs.writeSync = (fd, msg) ->
			arguments.length.should.equal 2
			fd.should.equal 82
			msg.should.equal "My log message.\n"
			failed++
			throw new Error 'Failed write'
		
		(-> L.log 'My log message.').should.throwError 'Failed write'
		failed.should.equal 1
		
		_fs.mock('closeSync').takes(82)
	
	test 'Logging fails writing silent', ->
		_path.mock('resolve').takes('.', 'foo.log').returns('/foo/bar/foo.log')
		_fs.mock('openSync').takes('/foo/bar/foo.log', 'a', 0o644).returns(82)
		_path.mock('dirname').takes('/foo/bar/foo.log').returns('/foo/bar')
		_fs.mock('existsSync').takes('/foo/bar').returns(yes)
		
		assert.ok L = new FileLogger new Config file: 'foo.log'
		
		failed = 0
		_fs.writeSync = (fd, msg) ->
			arguments.length.should.equal 2
			fd.should.equal 82
			msg.should.equal "My log message.\n"
			failed++
			throw new Error 'Failed write'
		
		L.log 'My log message.'
		failed.should.equal 1
		
		_fs.mock('closeSync').takes(82)
