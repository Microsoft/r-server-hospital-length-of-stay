var express = require('express');
var Connection = require('tedious').Connection;
var Request = require('tedious').Request;
var TYPES = require('tedious').TYPES;

var fs = require('fs');
var util = require('util');
var logFileName = __dirname + '/debug.log';

var app = express();
var exphbs = require('express-handlebars');
app.engine('handlebars', exphbs({ defaultLayout: 'main' }));
app.set('view engine', 'handlebars');

app.use(express.static('public'));

//
// DB Connection
//
var args = process.argv.slice(2);
var user = args[0];
var pw = args[1];

var ConnectionPool = require('tedious-connection-pool');
var Request = require('tedious').Request;

var poolConfig = {
  min: 2,
  max: 4,
  log: true
};

  var connectionConfig = {
    userName: 'Hospital_Py',
    password: 'LoSdemo2021',
    server: 'FLDSVRSDV01.upcic.inc',
    options: { encrypt: true, database: 'Hospital_Py' }

};

//create the pool 
var pool = new ConnectionPool(poolConfig, connectionConfig);

pool.on('error', function (err) {
  console.log('DB Connection ' + (err ? '~~~ Failure ~~~' : 'Success'));
  if (err) console.log(err);
});



//
// Put your routes here
//

// Home Page
app.get('/', function (req, res) {
  res.render('home')
});

app.get('/patient', function (req, res) {
  var id = req.query.id;
  res.render('patient', { id: id });
});

app.get('/patient2', function (req, res) {
  var id = req.query.id;
  res.render('patient2', { id: id });
});


// Kill the server
app.get('/kill', function (req, res) {
  setTimeout(() => process.exit(), 500);
});


// predict function, called from predLOS.js

app.get('/predict', function (req, res) {
  pool.acquire(function (err, con) {
    if (err) {
      console.error(err);
      con.release();
      return;
    }

    var request = new Request('do_native_predict', function (err, rowCount) {
      if (err) {
        console.log(err);
        con.release();      
        return;
      }
      con.release();
    });

    var eid = req.query.eid;
    console.log('Claim ID: ' + eid)
    request.on('row', function (col) {
      if (col[0].value === null) {
        console.log('NULL result');
      } else {
        // value to return - the predicted LOS
        value = col[0].value;
      }
      res.json({ pred: value });
      console.log("Prediction: " + value)
    });

    // pass the eid to the stored procedure
    request.addParameter('eid', TYPES.VarChar, eid);
    con.callProcedure(request);
  });

});

//log to file
var logFile = fs.createWriteStream(logFileName, { flags: 'a' });
var logProxy = console.log;
console.log = function (d) { //
  logFile.write(util.format(new Date() + ": " + d || '') + '\r\n');
  logProxy.apply(this, arguments);
};

app.listen(3000, function () {
  console.log('The website is running at http://localhost:3000');
});