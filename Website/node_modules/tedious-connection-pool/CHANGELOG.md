### Version 1.0.5
* no changes. published to update npm docs

### Version 1.0.4
* bug fix only

### Version 1.0.3
* Pool modifies the Tedious connection object rather than the Connection prototype.

### Version 1.0.2
* Added additional log message when acquiring a connection.

### Version 1.0.0
* No changes from v0.3.9.

### Version 0.3.9
* bug fix only

### Version 0.3.7
* bug fix only

### Version 0.3.6
* bug fix only

### Version 0.3.5
* `poolConfig` option `min` is limited to less than `max`

### Version 0.3.4
* `poolConfig` option `min` supports being set to 0

### Version 0.3.3
* Ignore calls to connection.release() on a connection that has been closed or not part of the connection pool.

### Version 0.3.2
 * Calls connection.reset() when the connection is released to the pool. This is very unlikely to cause anyone trouble.
 * Added a callback argument to connectionPool.drain()

### Version 0.3.0
 * Removed dependency on the `generic-pool` node module.
 * Added `poolConfig` options `retryDelay`
 * Added `poolConfig` options `aquireTimeout` **(Possibly Breaking)**
 * Added `poolConfig` options `log`
 * `idleTimeoutMillis` renamed to `idleTimeout` **(Possibly Breaking)**
 * The `ConnectionPool` `'error'` event added
 * The behavior of the err parameter of the callback passed to `acquire()` has changed. It only returns errors related to acquiring a connection not Tedious Connection errors. Connection errors can happen anytime the pool is being filled and could go unnoticed if only passed the the callback. Subscribe to the `'error'` event on the pool to be notified of all connection errors. **(Possibly Breaking)**
 * `PooledConnection` object removed.

### Version 0.2.x
* To acquire a connection, call on `acquire()` on a `ConnectionPool` rather than `requestConnection()`. **(Breaking)**
* After acquiring a `PooledConnection`, do not wait for the `'connected'` event. The connection is received connected. **(Breaking)**
* Call `release()` on a `PooledConnection` to release the it back to the pool. `close()` permanently closes the connection (as `close()` behaves in in tedious). **(Breaking)**
