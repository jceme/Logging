// Generated by CoffeeScript 1.6.3
(function() {
  var NoopLogger, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = NoopLogger = (function(_super) {
    __extends(NoopLogger, _super);

    function NoopLogger() {
      _ref = NoopLogger.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    NoopLogger.prototype.log = function() {};

    NoopLogger.prototype.toString = function() {
      return 'NoopLogger';
    };

    return NoopLogger;

  })(require('./AbstractLogger'));

}).call(this);