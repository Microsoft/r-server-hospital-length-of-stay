'use strict';

var _create = require('babel-runtime/core-js/object/create');

var _create2 = _interopRequireDefault(_create);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = require('babel-runtime/helpers/createClass');

var _createClass3 = _interopRequireDefault(_createClass2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var net = require('net');
var lookupAll = require('dns-lookup-all');

var Connector = function () {
  function Connector(options, multiSubnetFailover) {
    (0, _classCallCheck3.default)(this, Connector);

    this.options = options;
    this.multiSubnetFailover = multiSubnetFailover;
  }

  (0, _createClass3.default)(Connector, [{
    key: 'execute',
    value: function execute(cb) {
      if (net.isIP(this.options.host)) {
        this.executeForIP(cb);
      } else {
        this.executeForHostname(cb);
      }
    }
  }, {
    key: 'executeForIP',
    value: function executeForIP(cb) {
      var socket = net.connect(this.options);

      var onError = function onError(err) {
        socket.removeListener('error', onError);
        socket.removeListener('connect', onConnect);

        socket.destroy();

        cb(err);
      };

      var onConnect = function onConnect() {
        socket.removeListener('error', onError);
        socket.removeListener('connect', onConnect);

        cb(null, socket);
      };

      socket.on('error', onError);
      socket.on('connect', onConnect);
    }
  }, {
    key: 'executeForHostname',
    value: function executeForHostname(cb) {
      var _this = this;

      lookupAll(this.options.host, function (err, addresses) {
        if (err) {
          return cb(err);
        }

        if (_this.multiSubnetFailover) {
          new ParallelConnectionStrategy(addresses, _this.options).connect(cb);
        } else {
          new SequentialConnectionStrategy(addresses, _this.options).connect(cb);
        }
      });
    }
  }]);
  return Connector;
}();

var ParallelConnectionStrategy = function () {
  function ParallelConnectionStrategy(addresses, options) {
    (0, _classCallCheck3.default)(this, ParallelConnectionStrategy);

    this.addresses = addresses;
    this.options = options;
  }

  (0, _createClass3.default)(ParallelConnectionStrategy, [{
    key: 'connect',
    value: function connect(callback) {
      var addresses = this.addresses;
      var sockets = new Array(addresses.length);

      var errorCount = 0;
      var onError = function onError(err) {
        errorCount += 1;

        this.removeListener('error', onError);
        this.removeListener('connect', onConnect);

        if (errorCount === addresses.length) {
          callback(new Error('Could not connect (parallel)'));
        }
      };

      var onConnect = function onConnect() {
        for (var j = 0; j < sockets.length; j++) {
          var socket = sockets[j];

          if (this === socket) {
            continue;
          }

          socket.removeListener('error', onError);
          socket.removeListener('connect', onConnect);
          socket.destroy();
        }

        callback(null, this);
      };

      for (var i = 0, len = addresses.length; i < len; i++) {
        var socket = sockets[i] = net.connect((0, _create2.default)(this.options, {
          host: { value: addresses[i].address }
        }));

        socket.on('error', onError);
        socket.on('connect', onConnect);
      }
    }
  }]);
  return ParallelConnectionStrategy;
}();

var SequentialConnectionStrategy = function () {
  function SequentialConnectionStrategy(addresses, options) {
    (0, _classCallCheck3.default)(this, SequentialConnectionStrategy);

    this.addresses = addresses;
    this.options = options;
  }

  (0, _createClass3.default)(SequentialConnectionStrategy, [{
    key: 'connect',
    value: function connect(callback) {
      var _this2 = this;

      var addresses = this.addresses;

      if (!addresses.length) {
        callback(new Error('Could not connect (sequence)'));
        return;
      }

      var next = addresses.shift();

      var socket = net.connect((0, _create2.default)(this.options, {
        host: { value: next.address }
      }));

      var onError = function onError(err) {
        socket.removeListener('error', onError);
        socket.removeListener('connect', onConnect);

        socket.destroy();

        _this2.connect(callback);
      };

      var onConnect = function onConnect() {
        socket.removeListener('error', onError);
        socket.removeListener('connect', onConnect);

        callback(null, socket);
      };

      socket.on('error', onError);
      socket.on('connect', onConnect);
    }
  }]);
  return SequentialConnectionStrategy;
}();

module.exports.Connector = Connector;
module.exports.ParallelConnectionStrategy = ParallelConnectionStrategy;
module.exports.SequentialConnectionStrategy = SequentialConnectionStrategy;