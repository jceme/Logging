// Generated by CoffeeScript 1.6.3
(function() {
  'use strict';
  var Config, DEFAULT_TYPE, KEYS_LOGGERS;

  Config = require('./Config');

  DEFAULT_TYPE = 'ConsoleLogger';

  KEYS_LOGGERS = ['loggers', 'logger', 'adapters', 'adapter'];

  module.exports = {
    findAndConfigureLogging: function(logfilename) {
      var dir, last, logger, p, path;
      if (!logfilename) {
        throw new Error('File name required');
      }
      if (/^\//.test(logfilename)) {
        logger = this.createLoggersFrom(logfilename);
        if (logger != null) {
          return logger;
        }
      } else {
        dir = '.';
        last = null;
        path = require('path');
        while (true) {
          p = path.resolve(dir, logfilename);
          if (p === last) {
            break;
          }
          logger = this.createLoggersFrom(p);
          if (logger != null) {
            return logger;
          }
          last = p;
          dir += '/..';
        }
      }
      return this.createLoggers(new Config());
    },
    createLoggersFrom: function(filepath) {
      var JsonParser, content, fs, json;
      fs = require('fs');
      JsonParser = require('RelaxedJsonParser');
      if (fs.existsSync(filepath) && fs.statSync(filepath).isFile()) {
        content = fs.readFileSync(filepath).toString();
        json = JsonParser.parse(content);
        return this.createLoggers(new Config(json));
      }
      return null;
    },
    createLoggers: function(config) {
      var TeePseudoLogger, loggers, _ref,
        _this = this;
      loggers = (_ref = config.getOption.apply(config, KEYS_LOGGERS)) != null ? _ref : [{}];
      if (!(loggers instanceof Array)) {
        loggers = [loggers];
      }
      config.removeOption.apply(config, KEYS_LOGGERS);
      loggers = loggers.map(function(opts) {
        return _this.createLogger(new Config(opts, config));
      });
      if (loggers.length === 1) {
        return loggers[0];
      } else {
        TeePseudoLogger = require('../loggers/TeePseudoLogger');
        return new TeePseudoLogger(loggers);
      }
    },
    createLogger: function(config) {
      var clazz;
      clazz = this.resolveLoggerType(config.getOption('type'));
      return new clazz(config);
    },
    resolveLoggerType: function(type) {
      var T, e, types, _i, _len;
      if (type == null) {
        type = DEFAULT_TYPE;
      }
      type = ("" + type).trim();
      types = [];
      e = /^(\w+)(?:Adapter)?$/i.exec(type);
      if (e) {
        types.push("../loggers/" + type);
      }
      types.push(type);
      if (e) {
        types.push("../loggers/" + e[1] + "Logger");
      }
      for (_i = 0, _len = types.length; _i < _len; _i++) {
        T = types[_i];
        if (this.isResolvableType(T)) {
          return require(T);
        }
      }
      throw new Error("Cannot resolve logger type: " + type);
    },
    isResolvableType: function(type) {
      try {
        require.resolve(type);
        return true;
      } catch (_error) {
        return false;
      }
    }
  };

}).call(this);
