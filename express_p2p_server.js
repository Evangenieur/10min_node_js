// Generated by CoffeeScript 1.6.1
var Model, app, model, port, request, server;

Model = require("scuttlebutt/model");

model = new Model;

app = require("express")();

server = require("http").createServer(app);

/* HTTP P2P Server
*/


app.put("/_replicate", function(req, res) {
  console.log("replication req");
  return req.pipe(model.createStream()).pipe(res);
});

app.get("/", function(req, res) {
  var k, ret, v;
  console.log(req.query);
  return res.send((function() {
    var _ref, _results;
    _ref = req.query;
    _results = [];
    for (k in _ref) {
      v = _ref[k];
      ret = {};
      if (v) {
        model.set(k, v);
      }
      ret[k] = model.get(k);
      _results.push(ret);
    }
    return _results;
  })());
});

app.listen(Number(port = process.argv[2]));

console.log("Listening on port " + port);

request = require("request");

process.argv.slice(3).map(Number).forEach(function(peer_port) {
  var r;
  console.log("Replication to " + peer_port);
  r = request.put("http://localhost:" + peer_port + "/_replicate");
  return r.pipe(model.createStream()).pipe(r);
});
