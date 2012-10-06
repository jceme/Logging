// Generated by CoffeeScript 1.3.3
(function() {
  var ConsoleAdapter;

  module.exports = ConsoleAdapter = (function() {

    function ConsoleAdapter(_console) {
      if (_console == null) {
        _console = console;
      }
      this.fatal = _console.error || _console.log;
      this.error = _console.error || _console.log;
      this.warn = _console.warn || _console.log;
      this.info = _console.info || _console.log;
      this.debug = _console.debug || _console.log;
      this.trace = _console.debug || _console.log;
    }

    ConsoleAdapter.prototype.toString = function() {
      return 'ConsoleAdapter';
    };

    return ConsoleAdapter;

  })();

}).call(this);
