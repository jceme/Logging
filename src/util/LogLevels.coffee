module.exports = levels =

	Trace:   1
	Debug:   2
	Info:    4
	Warn:    8
	Error:   16
	Fatal:   32


Object.defineProperties levels,
	
	combine: value: combine = (lvls...) -> lvls.reduce ((p, c) -> p | c), 0
	
	combineLevels: value: (levelNames...) -> combine levelNames.map((n) -> levels[n])...
	
	isset: value: isset = (mask, level) -> mask & level
	
	isLevel: value: (mask, levelName) -> isset mask, levels[levelName]
