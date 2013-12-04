require 'should'

LogLevels = require '../../util/LogLevels'



suite 'LogLevels methods', ->
	
	test 'Sanity checks', ->
		v.should.be.type 'number' for v in ( v for _, v of LogLevels )
		( n: n, v: v for n, v of LogLevels ).sort((a, b) -> a.v - b.v).map((x) -> x.n).should.eql ['Trace', 'Debug', 'Info', 'Warn', 'Error', 'Fatal']
	
	test 'Combine and isset', ->
		LogLevels.combine().should.equal 0
		LogLevels.combineLevels().should.equal 0
		
		n = LogLevels.combine LogLevels.Debug, LogLevels.Warn
		n.should.be.ok
		n.should.equal LogLevels.combineLevels 'Debug', 'Warn'
		
		LogLevels.isset(n, LogLevels.Trace).should.not.be.ok
		LogLevels.isset(n, LogLevels.Debug).should.be.ok
		LogLevels.isset(n, LogLevels.Info).should.not.be.ok
		LogLevels.isset(n, LogLevels.Warn).should.be.ok
		LogLevels.isset(n, LogLevels.Error).should.not.be.ok
		LogLevels.isset(n, LogLevels.Fatal).should.not.be.ok
		
		LogLevels.isLevel(n, 'Trace').should.not.be.ok
		LogLevels.isLevel(n, 'Debug').should.be.ok
		LogLevels.isLevel(n, 'Info').should.not.be.ok
		LogLevels.isLevel(n, 'Warn').should.be.ok
		LogLevels.isLevel(n, 'Error').should.not.be.ok
		LogLevels.isLevel(n, 'Fatal').should.not.be.ok
