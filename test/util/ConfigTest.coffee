require 'should'
assert = require 'assert'


suite 'Config methods', ->

	Config = null
	
	setup -> Config = require '../../util/Config'
	
	
	test 'filterKeys', ->
		x = Config.filterKeys {a: 16, b: 'foo'}
		x.should.eql a: 16, b: 'foo'
		
		x = Config.filterKeys {a: 16, b: 'foo'}, 'test'
		x.should.eql a: 16, b: 'foo'
		x.should.not.have.property 'test'
		
		y = a: 16, b: 'foo'
		x = Config.filterKeys y, 'b'
		x.should.eql a: 16
		x.should.not.have.property 'b'
		y.should.eql a: 16, b: 'foo'
		
		y = a: 16, b: 'foo'
		x = Config.filterKeys y, 'test', 'b'
		x.should.eql a: 16
		x.should.not.have.property 'b'
		x.should.not.have.property 'test'
		y.should.eql a: 16, b: 'foo'
		
		y = a: 16, b: 'foo'
		x = Config.filterKeys y, 'a', 'b'
		x.should.not.have.property 'a'
		x.should.not.have.property 'b'
		y.should.eql a: 16, b: 'foo'
	
	test 'getOption and removeOption', ->
		c = new Config foo: 'bar', bar: 2, test: -> 18
		assert.equal c.getOption('noexist'), null
		c.getOption('foo').should.equal 'bar'
		c.getOption('bar').should.equal 2
		(c.getOption('test'))().should.equal 18
		c.getOption('foo', 'bar').should.equal 'bar'
		c.getOption('noexist', 'foo', 'bar').should.equal 'bar'
		
		c.removeOption 'foo'
		assert.equal c.getOption('foo'), null, 'Option foo not removed'
		c.getOption('foo', 'bar').should.equal 2
		c.getOption('noexist', 'foo', 'bar').should.equal 2
		
		c.removeOption()
		assert.equal c.getOption('foo'), null
		c.getOption('foo', 'bar').should.equal 2
		c.getOption('noexist', 'foo', 'bar').should.equal 2
	
	test 'getOption with parent', ->
		c1 = new Config foo: 'bar', bar: 19
		c = new Config {bar: 22}, c1
		
		c.getOption('bar').should.equal 22
		c.getOption('foo').should.equal 'bar'
		assert.equal c.getOption('noexist'), null
	
	test 'removeOption not escalating to parent', ->
		c1 = new Config foo: 'bar', bar: 19
		c = new Config {bar: 22}, c1
		
		c1.getOption('bar').should.equal 19
		c.getOption('bar').should.equal 22
		
		c.removeOption 'bar'
		c1.getOption('bar').should.equal 19
		c.getOption('bar').should.equal 19
