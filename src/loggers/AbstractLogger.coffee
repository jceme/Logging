module.exports = class AbstractLogger

	'use strict'
	
	_LogLevels = require '../util/LogLevels'
	Config = require '../util/Config'
	
	LogLevels = do ->
		l = {}
		l[do n.toLowerCase] = v for n, v of _LogLevels
		l
	
	SortedLogLevels = (n: n, v: v for n, v of LogLevels).sort((a, b) -> a.v - b.v).map((a) -> a.n)
	
	
	DEFAULT_LOG_LEVEL = 'INFO'
	
	DEFAULT_FORMAT_PATTERN = '%{DATETIME} %L  %n: %m'
	
	KEYS_FORMAT_PATTERN = [
		'formatPattern'
		'format'
		'pattern'
	]
	
	KEYS_LEVELS = [
		'levels'
		'level'
	]
	
	
	parseLevelConfig = (config) ->
		levelset = {}
		levels = Config.extend { '': DEFAULT_LOG_LEVEL }, config.getOption(KEYS_LEVELS...) ? {}
		
		min = LogLevels[config.getOption('min')?.toLowerCase()] ? 0
		max = LogLevels[config.getOption('max')?.toLowerCase()] ? Number.POSITIVE_INFINITY
		[max, min] = [min, max] if min > max
		
		for name, lvl of levels
			if typeof lvl is 'string'
				lvl = do lvl.toLowerCase
				
				switch
					# Special log level OFF to suppress logging
					when lvl is 'off' then n = []
					
					# Special log level ALL to allow any level
					when lvl is 'all' then n = SortedLogLevels
				
					when lvl of LogLevels
						n = []
						fnd = no
						for L in SortedLogLevels
							fnd = yes if L is lvl
							n.push L if fnd
					
					# Silently ignore invalid level name
					else continue
			
			else
				n = [].map.call(lvl, (x) -> do x.toLowerCase).filter((x) -> x of LogLevels)
			
			levelset[do name.trim] = _LogLevels.combine n.map((x) -> LogLevels[x]).filter((x) -> min <= x <= max)...
		
		levelset
	
	
	
	constructor: (config) ->
		@levelConfig = parseLevelConfig config
		
		@formatPattern = "#{config.getOption(KEYS_FORMAT_PATTERN...) ? DEFAULT_FORMAT_PATTERN}".replace /%\{(\w*)\}/g, (_, code) ->
			switch do code.toUpperCase
				when 'DATETIME'         then '%Y-%M-%D %H:%i:%s.%S'
				when 'DATETIME_ISO8601' then '%Y-%M-%DT%H:%i:%s.%S'
				when 'DATE'             then '%Y-%M-%D'
				when 'TIME'             then '%H:%i:%s.%S'
				else                         ''
	
	
	
	getLevelConfig: (parts) ->
		len = parts.length
		lvlcfg = @levelConfig
		while len >= 0
			testname = parts.slice(0, len--).join '.'
			
			if testname of lvlcfg then return mask: lvlcfg[testname]
		
		throw new Error 'Invalid internal level config'
	
	
	pad = (s, n = 2) ->
		s = "#{s}"
		s = "0#{s}" while s.length < n
		s
	
	rpad = (s, n) ->
		s = "#{s}"
		s += ' ' while s.length < n
		s
	
	formatLogMessage: (obj) ->
		@formatPattern.replace /%(\d+)?(\w|%)/g, (_, cnt, optchar) ->
			cnt = parseInt cnt, 10 if cnt?
			switch optchar
				when 'm' then obj.msg
				when 'n'
					if cnt? then obj.parts.slice(-1 - cnt).join '.'
					else obj.name
				when 'L' then rpad do obj.level.toUpperCase, cnt ? 5
				when 'D' then pad do obj.date.getDate, cnt
				when 'M' then pad 1 + do obj.date.getMonth, cnt
				when 'Y' then pad do obj.date.getFullYear, cnt ? 0
				when 'H' then pad do obj.date.getHours, cnt
				when 'i' then pad do obj.date.getMinutes, cnt
				when 's' then pad do obj.date.getSeconds, cnt
				when 'S' then pad do obj.date.getMilliseconds, cnt ? 3
				when 'T' then pad do obj.date.getTime, cnt ? 0
				when '%' then '%'
				else          ''
	
	
	logMessage: (obj) -> @log @formatLogMessage obj
