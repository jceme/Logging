// Generated by CoffeeScript 1.6.3
(function() {
  var Config,
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  module.exports = Config = (function() {
    'use strict';
    Config.filterKeys = function() {
      var f, k, keys, obj, v;
      obj = arguments[0], keys = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      f = {};
      for (k in obj) {
        v = obj[k];
        if (__indexOf.call(keys, k) < 0) {
          f[k] = v;
        }
      }
      return f;
    };

    Config.extend = function() {
      var f, k, obj, objs, v, _i, _len;
      objs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      f = {};
      for (_i = 0, _len = objs.length; _i < _len; _i++) {
        obj = objs[_i];
        for (k in obj) {
          v = obj[k];
          f[k] = v;
        }
      }
      return f;
    };

    function Config(opts, parent) {
      this.opts = opts != null ? opts : {};
      this.parent = parent;
    }

    Config.prototype.getOption = function() {
      var keynames, _ref;
      keynames = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (_ref = this.getOptionWithKey.apply(this, keynames)) != null ? _ref.value : void 0;
    };

    Config.prototype.getOptionWithKey = function() {
      var key, keynames, opts, _i, _len, _ref;
      keynames = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      opts = this.opts;
      for (_i = 0, _len = keynames.length; _i < _len; _i++) {
        key = keynames[_i];
        if (key in opts) {
          return {
            key: key,
            value: opts[key]
          };
        }
      }
      return (_ref = this.parent) != null ? _ref.getOptionWithKey.apply(_ref, keynames) : void 0;
    };

    Config.prototype.removeOption = function() {
      var keynames;
      keynames = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.opts = Config.filterKeys.apply(Config, [this.opts].concat(__slice.call(keynames)));
    };

    return Config;

  })();

}).call(this);
