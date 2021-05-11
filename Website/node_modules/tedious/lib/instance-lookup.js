'use strict';

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = require('babel-runtime/helpers/createClass');

var _createClass3 = _interopRequireDefault(_createClass2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Sender = require('./sender').Sender;

var SQL_SERVER_BROWSER_PORT = 1434;
var TIMEOUT = 2 * 1000;
var RETRIES = 3;
// There are three bytes at the start of the response, whose purpose is unknown.
var MYSTERY_HEADER_LENGTH = 3;

// Most of the functionality has been determined from from jTDS's MSSqlServerInfo class.

var InstanceLookup = function () {
  function InstanceLookup() {
    (0, _classCallCheck3.default)(this, InstanceLookup);
  }

  // Wrapper allows for stubbing Sender when unit testing instance-lookup.


  (0, _createClass3.default)(InstanceLookup, [{
    key: 'createSender',
    value: function createSender(host, port, request) {
      return new Sender(host, port, request);
    }
  }, {
    key: 'instanceLookup',
    value: function instanceLookup(options, callback) {
      var _this = this;

      var server = options.server;
      if (typeof server !== 'string') {
        throw new TypeError('Invalid arguments: "server" must be a string');
      }

      var instanceName = options.instanceName;
      if (typeof instanceName !== 'string') {
        throw new TypeError('Invalid arguments: "instanceName" must be a string');
      }

      var timeout = options.timeout === undefined ? TIMEOUT : options.timeout;
      if (typeof timeout !== 'number') {
        throw new TypeError('Invalid arguments: "timeout" must be a number');
      }

      var retries = options.retries === undefined ? RETRIES : options.retries;
      if (typeof retries !== 'number') {
        throw new TypeError('Invalid arguments: "retries" must be a number');
      }

      if (typeof callback !== 'function') {
        throw new TypeError('Invalid arguments: "callback" must be a function');
      }

      var sender = void 0,
          timer = void 0,
          retriesLeft = retries;

      var onTimeout = function onTimeout() {
        sender.cancel();
        return makeAttempt();
      };

      var makeAttempt = function makeAttempt() {
        if (retriesLeft > 0) {
          retriesLeft--;

          var request = new Buffer([0x02]);
          sender = _this.createSender(options.server, SQL_SERVER_BROWSER_PORT, request);
          sender.execute(function (err, message) {
            clearTimeout(timer);
            if (err) {
              return callback('Failed to lookup instance on ' + server + ' - ' + err.message);
            } else {
              message = message.toString('ascii', MYSTERY_HEADER_LENGTH);
              var port = _this.parseBrowserResponse(message, instanceName);

              if (port) {
                return callback(undefined, port);
              } else {
                return callback('Port for ' + instanceName + ' not found in ' + message);
              }
            }
          });

          return timer = setTimeout(onTimeout, timeout);
        } else {
          return callback('Failed to get response from SQL Server Browser on ' + server);
        }
      };

      return makeAttempt();
    }
  }, {
    key: 'parseBrowserResponse',
    value: function parseBrowserResponse(response, instanceName) {
      var getPort = void 0;

      var instances = response.split(';;');
      for (var i = 0, len = instances.length; i < len; i++) {
        var instance = instances[i];
        var parts = instance.split(';');

        for (var p = 0, partsLen = parts.length; p < partsLen; p += 2) {
          var name = parts[p];
          var value = parts[p + 1];

          if (name === 'tcp' && getPort) {
            var port = parseInt(value, 10);
            return port;
          }

          if (name === 'InstanceName') {
            if (value.toUpperCase() === instanceName.toUpperCase()) {
              getPort = true;
            } else {
              getPort = false;
            }
          }
        }
      }
    }
  }]);
  return InstanceLookup;
}();

module.exports.InstanceLookup = InstanceLookup;