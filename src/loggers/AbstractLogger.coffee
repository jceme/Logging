module.exports = class AbstractLogger

	'use strict'
	
	LogLevels = do ->
		l = {}
		l[do n.toLowerCase] = v for n, v of require '../LogLevels'
		l
	
	SortedLogLevels = (n: n, v: v for n, v of LogLevels).sort((a, b) -> b.v - a.v).map((a) -> a.n)
	
	
	DEFAULT_LOG_LEVEL = 'INFO'
	
	
	parseLevelConfig = (opts) ->
		levelset = {}
		levels = opts.levels ? {}
		levels[''] ?= DEFAULT_LOG_LEVEL
		
		min = LogLevels[do opts.min?.toLowerCase] ? 0
		max = LogLevels[do opts.max?.toLowerCase] ? Number.POSITIVE_INFINITY
		[max, min] = [min, max] if min > max
		
		for name, lvl of levels
			if typeof lvl is 'string'
				lvl = do lvl.toLowerCase
				n = []
				if lvl of LogLevels
					fnd = no
					for L in SortedLogLevels
						fnd = yes if L is lvl
						n.push L if fnd
			else
				n = [].map.call(lvl, (x) -> do x.toLowerCase).filter((x) -> x of LogLevels)
			
			levelset[do name.trim] = n
			.map((x) -> LogLevels[x])
			.filter((x) -> min <= x <= max)
			.reduce ((p, c) -> p | c), 0
		
		levelset
	
	
	constructor: (opts = {}) ->
		@levelConfig = parseLevelConfig opts
		
		@formatPattern = (opts.formatPattern ? opts.formatPattern ? opts.formatPattern ? '%{DATETIME} [%L] %n: %m')
		.replace /%\{(\w*)\}/g, (_, code) ->
			switch do code.toUpperCase
				when 'DATETIME'         then '%Y-%M-%D %H:%i%s.%S'
				when 'DATETIME_ISO8601' then '%Y-%M-%DT%H:%i%s.%S'
				when 'DATE'             then '%Y-%M-%D'
				when 'TIME'             then '%H:%i%s.%S'
				else                         ''
		
	
	
	getLevelConfig: (parts) ->
		len = parts.length
		while len >= 0
			testname = parts.slice(0, len--).join '.'
			levelset = @levelConfig[testname]
			
			return levelset if levelset?
		
		return null
	
	
	pad = (s, n = 2) ->
		s = "#{s}"
		s = "0#{s}" while s.length < n
		s
	
	formatLogMessage: (obj) ->
		@formatPattern.replace /%(\d+)?(\w)/g, (_, cnt, optchar) ->
			switch optchar
				when 'm' then obj.msg
				when 'n'
					if cnt? then obj.parts.slice(-1 - parseInt cnt, 10).join '.'
					else obj.name
				when 'L' then do obj.level.toUpperCase
				when 'D' then pad do obj.date.getDate
				when 'M' then pad 1 + do obj.date.getMonth
				when 'Y' then do obj.date.getFullYear
				when 'H' then pad do obj.date.getHours
				when 'i' then pad do obj.date.getMinutes
				when 's' then pad do obj.date.getSeconds
				when 'S' then pad do obj.date.getMilliseconds, 3
				when 'T' then do obj.date.getTime
				else          ''
	
	
	logMessage: (obj) -> log formatLogMessage obj
