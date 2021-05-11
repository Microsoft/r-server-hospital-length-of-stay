'use strict';

var semver = require('semver');
var dns = require('dns');

var lookupAll;

if (semver.lt(process.version, '1.2.0')) {
  lookupAll = function lookupAll(domain, family_, callback_) {
    var family, callback;

    if (arguments.length == 2) {
      callback = family_;
    } else {
      callback = callback_;
      family = family_;
    }

    var req = dns.lookup(domain, family, function(err, address, family) {
      if (err) {
        return callback(err);
      }

      callback(null, [ { address: address, family: family } ]);
    });
    var oldHandler = req.oncomplete;

    if (oldHandler && oldHandler.length == 2) {
      req.oncomplete = function onlookupall(err, addresses) {
        if (err) {
          return oldHandler.call(this, err);
        }

        var results = [];
        for (var i = 0; i < addresses.length; i++) {
          results.push({
            address: addresses[i],
            family: family || (addresses[i].indexOf(':') >= 0 ? 6 : 4)
          });
        }

        callback(null, results);
      };
    } else {
      req.oncomplete = function onlookupall(addresses) {
        if (!addresses) {
          return oldHandler.call(this, addresses);
        }

        var results = [];
        for (var i = 0; i < addresses.length; i++) {
          results.push({
            address: addresses[i],
            family: family || (addresses[i].indexOf(':') >= 0 ? 6 : 4)
          });
        }

        callback(null, results);
      };
    }

    return req;
  };
} else {
  lookupAll = function lookupAll(domain, family_, callback_) {
    var family, callback, options = { all: true };

    if (arguments.length === 2) {
      callback = family_;
    } else {
      callback = callback_;
      options.family = family_;
    }

    return dns.lookup(domain, options, callback);
  };
}

module.exports = lookupAll;
