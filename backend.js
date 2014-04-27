
var express = require('express');
var mongo = require('mongodb').MongoClient;
var format = require('util').format;

var app = express();

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
      console.log(docs);
    });
  });
});

app.listen(3000);
