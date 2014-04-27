
var express = require('express');
var mongo = require('mongodb').MongoClient;
var format = require('util').format;

var app = express();

app.all('*', function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "X-Requested-With");
  next();
});

app.get('/stations', function(req, res) {
  mongo.connect('mongodb://127.0.0.1:27017/test', function(err, db) {
    if (err) throw err;

    var collection = db.collection('dailytemps');
    // collection
    //   .find({})
    //   .limit(10)
    //   .toArray(function(err, docs) {
    //     console.log(docs);
    //   });
    collection.distinct('station', function(err, docs) {
      res.send(docs);
    });
  });
});

app.get('/stations/:wmo', function(req, res) {
  console.log(req.params.wmo);
  mongo.connect('mongodb://127.0.0.1:27017/test', function(err, db) {
    if (err) throw err;

    var collection = db.collection('dailytemps');
    collection
      .find({})
      .toArray(function(err, docs) {
        console.log(docs);
      });
    });
  });
});

app.listen(3000);
