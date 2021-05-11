var lookupAll = require('..');
var assert = require('chai').assert;

describe('lookupAll', function() {
  it('returns a list of IP addresses for the looked up domain name', function(done) {
    lookupAll('localhost', function(err, results) {
      if (err) {
        return done(err);
      }

      assert.deepEqual(results, [
        { address: '127.0.0.1', family: 4 },
        { address: '::1', family: 6 }
      ]);

      done();
    });
  });

  it('allows limiting the returned addresses to IPv6', function(done) {
    lookupAll('localhost', 6, function(err, results) {
      if (err) {
        return done(err);
      }

      assert.isAtLeast(results.length, 1);

      results.forEach(function(result) {
        assert.deepEqual(result, { address: '::1', family: 6 });
      })

      done();
    });
  });

  it('allows limiting the returned addresses to IPv4', function(done) {
    lookupAll('localhost', 4, function(err, results) {
      if (err) {
        return done(err);
      }

      assert.isAtLeast(results.length, 1);

      results.forEach(function(result) {
        assert.deepEqual(result, { address: '127.0.0.1', family: 4 });
      });

      done();
    });
  });
});
