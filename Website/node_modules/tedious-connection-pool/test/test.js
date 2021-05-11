'use strict';
var assert = require('assert');
var Request = require('tedious').Request;
var ConnectionPool = require('../lib/connection-pool');
var Connection = require('tedious').Connection;

var connectionConfig, timeout;

if (process.env.APPVEYOR) {
    timeout = 30000;
    connectionConfig = {
        server: 'localhost',
        userName: 'sa',
        password: 'Password12!',
        options: {
            appName: 'pool-test',
            database: 'master',
            requestTimeout: 25000,
            cryptoCredentialsDetails: {
                ciphers: 'RC4-MD5'
            }
        }
    };
} else {
    timeout = 10000;
    connectionConfig = {
        userName: 'test',
        password: 'test',
        server: 'dev1',
        options: {
            appName: 'pool-test',
            database: 'test'
        }
    };
}

/* create a db user with the correct permissions:
CREATE DATABASE test
CREATE LOGIN test WITH PASSWORD=N'test', DEFAULT_DATABASE=test, CHECK_POLICY=OFF
GRANT ALTER ANY CONNECTION TO test

USE test
CREATE USER test FOR LOGIN test WITH DEFAULT_SCHEMA=dbo
ALTER ROLE db_owner ADD MEMBER test

USE msdb
CREATE USER test FOR LOGIN test WITH DEFAULT_SCHEMA=dbo
ALTER ROLE SQLAgentOperatorRole ADD MEMBER test
ALTER ROLE SQLAgentReaderRole ADD MEMBER test
ALTER ROLE SQLAgentUserRole ADD MEMBER test
*/

/* disable the user when not testing:
ALTER LOGIN test DISABLE
*/

describe('Name Collision', function () {

    it('release', function () {
        assert(!Connection.prototype.release);

        var con = new Connection({});
        assert(!con.release);
        con.close();
    });

    it('pool', function () {
        assert(!Connection.prototype.pool);

        var con = new Connection({});
        assert(!con.pool);
        con.close();
    });
});

describe('ConnectionPool', function () {

    it('min', function (done) {
        this.timeout(timeout);

        var poolConfig = {min: 2};
        var pool = new ConnectionPool(poolConfig, connectionConfig);

        setTimeout(function() {
            assert.equal(pool.connections.length, poolConfig.min);
            pool.drain(done);
        }, 4);
    });

    it('min=0', function (done) {
        this.timeout(timeout);

        var poolConfig = {min: 0, idleTimeout: 10};
        var pool = new ConnectionPool(poolConfig, connectionConfig);

        setTimeout(function() {
            assert.equal(pool.connections.length, 0);
        }, 4);

        setTimeout(function() {
            pool.acquire(function(err, connection) {
                assert(!err);

                var request = new Request('select 42', function (err, rowCount) {
                    assert.strictEqual(rowCount, 1);
                    connection.release();
                    setTimeout(function () {
                        assert.equal(pool.connections.length, 0);
                        pool.drain(done);
                    }, 200);
                });

                request.on('row', function (columns) {
                    assert.strictEqual(columns[0].value, 42);
                });

                connection.execSql(request);
            });
        }, 2000);
    });

    it('max', function (done) {
        this.timeout(timeout);

        var poolConfig = {min: 2, max: 5};
        var pool = new ConnectionPool(poolConfig, connectionConfig);

        var count = 20;
        var run = 0;

        var createRequest = function (err, connection) {
            assert(!err);

            var request = new Request('select 42', function (err, rowCount) {
                assert.strictEqual(rowCount, 1);
                setTimeout(function() {
                    run++;
                    assert(pool.connections.length <= poolConfig.max);
                    if (run === count) {
                        pool.drain(done);
                        return;
                    }
                    connection.release();
                }, 200);
            });

            request.on('row', function (columns) {
                assert.strictEqual(columns[0].value, 42);
            });

            connection.execSql(request);
        };

        for (var i = 0; i < count; i++) {
            setTimeout(function() {
                pool.acquire(createRequest);
            }, 1);
        }
    });

    it('min<=max, min specified > max specified', function (done) {
        this.timeout(timeout);

        var poolConfig = { min: 5, max: 1, idleTimeout: 10};
        var pool = new ConnectionPool(poolConfig, connectionConfig);

        setTimeout(function() {
            assert.equal(pool.connections.length, 1);
        }, 4);

        setTimeout(function() {
            pool.acquire(function(err, connection) {
                assert(!err);

                var request = new Request('select 42', function (err, rowCount) {
                    assert.strictEqual(rowCount, 1);
                    connection.release();
                    setTimeout(function () {
                        assert.equal(pool.connections.length, 1);
                        pool.drain(done);
                    }, 200);
                });

                request.on('row', function (columns) {
                    assert.strictEqual(columns[0].value, 42);
                });

                connection.execSql(request);
            });
        }, 2000);
    });

    it('min<=max, no min specified', function (done) {
        this.timeout(timeout);

        var poolConfig = {max: 1, idleTimeout: 10};
        var pool = new ConnectionPool(poolConfig, connectionConfig);

        setTimeout(function() {
            assert.equal(pool.connections.length, 1);
        }, 4);

        setTimeout(function() {
            pool.acquire(function(err, connection) {
                assert(!err);

                var request = new Request('select 42', function (err, rowCount) {
                    assert.strictEqual(rowCount, 1);
                    connection.release();
                    setTimeout(function () {
                        assert.equal(pool.connections.length, 1);
                        pool.drain(done);
                    }, 200);
                });

                request.on('row', function (columns) {
                    assert.strictEqual(columns[0].value, 42);
                });

                connection.execSql(request);
            });
        }, 2000);
    });

    it('pool error event', function (done) {
        this.timeout(timeout);
        var poolConfig = {min: 3};
        var pool = new ConnectionPool(poolConfig, {});

        pool.acquire(function() { });

        pool.on('error', function(err) {
            assert(!!err);
            pool.drain(done);
        });
    });

    it('connection retry', function (done) {
        this.timeout(timeout);
        var poolConfig = {min: 1, max: 5, retryDelay: 5};
        var pool = new ConnectionPool(poolConfig, {});

        pool.on('error', function(err) {
            assert(!!err);
            pool.connectionConfig = connectionConfig;
        });

        function testConnected() {
            for (var i = pool.connections.length - 1; i >= 0; i--) {
                if (pool.connections[i].status === 3/*RETRY*/) {
                    setTimeout(testConnected, 100);
                    return;
                }
            }

            assert.equal(pool.connections.length, poolConfig.min);
            pool.drain(done);
        }

        setTimeout(testConnected, 100);
    });

    it('acquire timeout', function (done) {
        this.timeout(timeout);

        var poolConfig = {min: 1, max: 1, acquireTimeout: 2000};
        var pool = new ConnectionPool(poolConfig, connectionConfig);

        pool.acquire(function(err, connection) {
            assert(!err);
            assert(!!connection);
        });

        pool.acquire(function(err, connection) {
            assert(!!err);
            assert(!connection);
            done();
        });
    });

    it('idle timeout', function (done) {
        this.timeout(timeout);
        var poolConfig = {min: 1, max: 5, idleTimeout: 100};
        var pool = new ConnectionPool(poolConfig, connectionConfig);

        setTimeout(function() {
            pool.acquire(function (err, connection) {
                assert(!err);

                var request = new Request('select 42', function (err, rowCount) {
                    assert.strictEqual(rowCount, 1);
                    pool.drain(done);
                });

                request.on('row', function (columns) {
                    assert.strictEqual(columns[0].value, 42);
                });

                connection.execSql(request);
            });

        }, 300);
    });

    it('connection error handling', function (done) {
        this.timeout(timeout);
        var poolConfig = {min: 1, max: 5};

        var pool = new ConnectionPool(poolConfig, connectionConfig);

        pool.on('error', function(err) {
            assert(err && err.name === 'ConnectionError');
        });

        //This simulates a lost connections by creating a job that kills the current session and then deletesthe job.
        pool.acquire(function (err, connection) {
            assert(!err);

            var command = 'DECLARE @jobName VARCHAR(68) = \'pool\' + CONVERT(VARCHAR(64),NEWID()), @jobId UNIQUEIDENTIFIER;' +
            'EXECUTE msdb..sp_add_job @jobName, @owner_login_name=\'' + connectionConfig.userName + '\', @job_id=@jobId OUTPUT;' +
            'EXECUTE msdb..sp_add_jobserver @job_id=@jobId;' +

            'DECLARE @cmd VARCHAR(50);' +
            'SELECT @cmd = \'kill \' + CONVERT(VARCHAR(10), @@SPID);' +
            'EXECUTE msdb..sp_add_jobstep @job_id=@jobId, @step_name=\'Step1\', @command = @cmd, @database_name = \'' + connectionConfig.options.database + '\', @on_success_action = 3;' +

            'DECLARE @deleteCommand VARCHAR(200);' +
            'SET @deleteCommand = \'execute msdb..sp_delete_job @job_name=\'\'\'+@jobName+\'\'\'\';' +
            'EXECUTE msdb..sp_add_jobstep @job_id=@jobId, @step_name=\'Step2\', @command = @deletecommand;' +

            'EXECUTE msdb..sp_start_job @job_id=@jobId;' +
            'WAITFOR DELAY \'01:00:00\';' +
            'SELECT 42';

            var request = new Request(command, function (err, rowCount) {
                assert(err);
                pool.drain(done);
            });

            request.on('row', function (columns) {
                assert(false);
            });

            connection.execSql(request);
        });
    });

    it('release(), reset()', function (done) {
        this.timeout(timeout);

        var poolConfig = {max: 1};
        var pool = new ConnectionPool(poolConfig, connectionConfig);

        var createRequest = function(query, value, callback) {
            var request = new Request(query, function (err, rowCount) {
                assert.strictEqual(rowCount, 1);
                callback();
            });

            request.on('row', function (columns) {
                assert.strictEqual(columns[0].value, value);
            });

            return request;
        };

        pool.acquire(function(err, conn) {
            assert(!err);

            conn.execSql(createRequest('SELECT 42', 42, function () {
                pool.release(conn); //release the connect

                pool.acquire(function (err, conn) { //re-acquire the connection
                    assert(!err);

                    conn.execSql(createRequest('SELECT 42', 42, function () {

                        pool.drain(done);
                    }));
                });
            }));
        });
    });

    it('drain', function (done) {
        this.timeout(timeout);

        var poolConfig = {min: 3};
        var pool = new ConnectionPool(poolConfig, connectionConfig);

        pool.acquire(function() { });

        setTimeout(function() {
            assert.equal(pool.connections.length, poolConfig.min);
            pool.drain(done);
        }, 4);
    });
});

if (!process.env.APPVEYOR) {
    describe('Load Test', function () {
        var statistics = require('simple-statistics');
        
        it('Memory Leak Detection - Connection Error', function (done) {
            this.timeout(60000);
            if (!global.gc)
                throw new Error('must run nodejs with --expose-gc');
            var count = 0;
            var mem = [];
            var groupCount = 20;
            var poolSize = 1000;
            var max = poolSize * groupCount;
            
            var pool = new ConnectionPool({max: poolSize, min: poolSize, retryDelay: 1}, {
                userName: 'testLogin',
                password: 'wrongPassword',
                server: 'localhost'
            });
            
            pool.on('error', function () {
                if ((++count % poolSize) !== 0)
                    return;
                
                global.gc();
                
                var heapUsedKB = Math.round(process.memoryUsage().heapUsed / 1024);
                mem.push([count, heapUsedKB]);
                // console.log(count + ': ' + heapUsedKB + 'KB');
                
                if (count === max) {
                    var data = statistics.linearRegression(mem);
                    //console.log(data.m);
                    if (data.m >= 0.025)
                        done(new Error('Memory leak detected.'));
                    else
                        done();
                    
                    pool.drain();
                }
            });
        });
        
        it('Memory Leak Detection - acquire() and Request', function (done) {
            this.timeout(60000);
            if (!global.gc)
                throw new Error('must run nodejs with --expose-gc');
            
            var poolConfig = {min: 67, max: 123};
            var pool = new ConnectionPool(poolConfig, {
                userName: 'test',
                password: 'test',
                server: 'dev1'
            });
            
            var clients = 1000;
            var connections = 100;
            var max = clients * connections;
            var mem = [];
            
            for (var i = 0; i < clients; i++)
                createClient();
            
            var count = 0;
            
            function end(err) {
                done(err);
                pool.drain();
            }
            
            function createClient() {
                var clientCount = 0;
                
                function createRequest() {
                    pool.acquire(function (err, connection) {
                        if (err)
                            return end(err);
                        
                        var request = new Request('select 42', function (err) {
                            if (err)
                                return end(err);
                            
                            connection.release();
                            
                            if (++clientCount < connections)
                                createRequest();
                            
                            if ((++count % 1000) === 0) {
                                global.gc();
                                
                                if (count === max) {
                                    var data = statistics.linearRegression(mem);
                                    //console.log(data.m);
                                    if (data.m >= 0.025)
                                        end(new Error('Memory leak not detected.'));
                                    else
                                        end();
                                } else {
                                    var heapUsedKB = Math.round(process.memoryUsage().heapUsed / 1024);
                                    mem.push([count, heapUsedKB]);
                                    // console.log(count + ': ' + heapUsedKB + 'KB');
                                }
                            }
                        });
                        
                        connection.execSql(request);
                    });
                }
                
                createRequest();
            }
        });
    });
}