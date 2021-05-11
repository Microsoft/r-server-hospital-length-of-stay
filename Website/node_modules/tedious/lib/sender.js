'use strict';

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = require('babel-runtime/helpers/createClass');

var _createClass3 = _interopRequireDefault(_createClass2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var dgram = require('dgram');
var lookupAll = require('dns-lookup-all');
var net = require('net');

var Sender = function () {
  function Sender(host, port, request) {
    (0, _classCallCheck3.default)(this, Sender);

    this.host = host;
    this.port = port;
    this.request = request;

    this.parallelSendStrategy = null;
  }

  (0, _createClass3.default)(Sender, [{
    key: 'execute',
    value: function execute(cb) {
      if (net.isIP(this.host)) {
        this.executeForIP(cb);
      } else {
        this.executeForHostname(cb);
      }
    }
  }, {
    key: 'executeForIP',
    value: function executeForIP(cb) {
      this.executeForAddresses([{ address: this.host }], cb);
    }

    // Wrapper for stubbing. Sinon does not have support for stubbing module functions.

  }, {
    key: 'invokeLookupAll',
    value: function invokeLookupAll(host, cb) {
      lookupAll(host, cb);
    }
  }, {
    key: 'executeForHostname',
    value: function executeForHostname(cb) {
      var _this = this;

      this.invokeLookupAll(this.host, function (err, addresses) {
        if (err) {
          return cb(err);
        }

        _this.executeForAddresses(addresses, cb);
      });
    }

    // Wrapper for stubbing creation of Strategy object. Sinon support for constructors
    // seems limited.

  }, {
    key: 'createParallelSendStrategy',
    value: function createParallelSendStrategy(addresses, port, request) {
      return new ParallelSendStrategy(addresses, port, request);
    }
  }, {
    key: 'executeForAddresses',
    value: function executeForAddresses(addresses, cb) {
      this.parallelSendStrategy = this.createParallelSendStrategy(addresses, this.port, this.request);
      this.parallelSendStrategy.send(cb);
    }
  }, {
    key: 'cancel',
    value: function cancel() {
      if (this.parallelSendStrategy) {
        this.parallelSendStrategy.cancel();
      }
    }
  }]);
  return Sender;
}();

var ParallelSendStrategy = function () {
  function ParallelSendStrategy(addresses, port, request) {
    (0, _classCallCheck3.default)(this, ParallelSendStrategy);

    this.addresses = addresses;
    this.port = port;
    this.request = request;

    this.socketV4 = null;
    this.socketV6 = null;
    this.onError = null;
    this.onMessage = null;
  }

  (0, _createClass3.default)(ParallelSendStrategy, [{
    key: 'clearSockets',
    value: function clearSockets() {
      var clearSocket = function clearSocket(socket, onError, onMessage) {
        socket.removeListener('error', onError);
        socket.removeListener('message', onMessage);
        socket.close();
      };

      if (this.socketV4) {
        clearSocket(this.socketV4, this.onError, this.onMessage);
        this.socketV4 = null;
      }

      if (this.socketV6) {
        clearSocket(this.socketV6, this.onError, this.onMessage);
        this.socketV6 = null;
      }
    }
  }, {
    key: 'send',
    value: function send(cb) {
      var _this2 = this;

      var errorCount = 0;

      var onError = function onError(err) {
        errorCount++;

        if (errorCount === _this2.addresses.length) {
          _this2.clearSockets();
          cb(err);
        }
      };

      var onMessage = function onMessage(message) {
        _this2.clearSockets();
        cb(null, message);
      };

      var createDgramSocket = function createDgramSocket(udpType, onError, onMessage) {
        var socket = dgram.createSocket(udpType);

        socket.on('error', onError);
        socket.on('message', onMessage);
        return socket;
      };

      for (var j = 0; j < this.addresses.length; j++) {
        var udpTypeV4 = 'udp4';
        var udpTypeV6 = 'udp6';

        var udpType = net.isIPv4(this.addresses[j].address) ? udpTypeV4 : udpTypeV6;
        var socket = void 0;

        if (udpType === udpTypeV4) {
          if (!this.socketV4) {
            this.socketV4 = createDgramSocket(udpTypeV4, onError, onMessage);
          }

          socket = this.socketV4;
        } else {
          if (!this.socketV6) {
            this.socketV6 = createDgramSocket(udpTypeV6, onError, onMessage);
          }

          socket = this.socketV6;
        }

        socket.send(this.request, 0, this.request.length, this.port, this.addresses[j].address);
      }

      this.onError = onError;
      this.onMessage = onMessage;
    }
  }, {
    key: 'cancel',
    value: function cancel() {
      this.clearSockets();
    }
  }]);
  return ParallelSendStrategy;
}();

module.exports.Sender = Sender;
module.exports.ParallelSendStrategy = ParallelSendStrategy;