// Generated by CoffeeScript 1.6.1
var Model, app, es, io, model, port, request, server;

Model = require("scuttlebutt/model");

es = require('event-stream');

model = new Model;

app = require("express")();

server = require("http").createServer(app);

port = Number(process.argv[2]);

/* HTTP P2P Server
*/


app.put("/_replicate", function(req, res) {
  return req.pipe(model.createStream()).pipe(res);
});

app.get("/", function(req, res) {
  return res.send("<body>\n  <textarea id=\"chat\" cols=\"40\" rows=\"5\"></textarea>\n  <div id=\"info\"></div>\n  <script src=\"/socket.io/socket.io.js\"></script>\n  <script>\n    var chat = document.getElementById(\"chat\"), \n      socket = io.connect(\"http://localhost:" + port + "\", {\n          \"reconnect\": true,\n          \"reconnection delay\": 500,\n          \"max reconnection attempts\": 99999\n        }),\n      myself_emitted = false,\n      info = document.getElementById(\"info\");\n\n    socket.on('connect', function() {\n      info.innerHTML = \"connected to " + port + "\";\n    });\n    socket.on('disconnect', function() {\n      info.innerHTML = \"disconnected\";\n    });\n\n    socket.on('chat', function (data) {\n      if (!myself_emitted) {\n        chat.value = data;\n      } \n      myself_emitted = false;\n    });\n\n    chat.addEventListener( \"keyup\",\n      function(e) {\n        myself_emitted = true;\n        socket.emit(\"chat\", chat.value)\n      }\n    );\n  </script>\n</body>");
});

server.listen(port);

console.log("Listening on port " + port);

request = require("request");

process.argv.slice(3).map(Number).forEach(function(peer_port) {
  var r;
  console.log("Replication to " + peer_port);
  r = request.put("http://localhost:" + peer_port + "/_replicate");
  return r.pipe(model.createStream()).pipe(r);
});

/* Socket.io
*/


io = require("socket.io").listen(server);

io.set("log level", 0);

io.sockets.on("connection", function(socket) {
  console.log("Connection");
  socket.emit("chat", model.get("chat"));
  socket.on("chat", function(v) {
    console.log("chat", v);
    return model.set("chat", v);
  });
  return model.createStream().pipe(es.map(function(raw_data, cb) {
    var data, k, v, _ref, _ref1;
    data = JSON.parse(raw_data);
    if ((typeof data === "object") && (((_ref = data[0]) != null ? _ref.length : void 0) != null)) {
      _ref1 = data[0], k = _ref1[0], v = _ref1[1];
      if (k === "chat") {
        return socket.emit("chat", v);
      }
    }
  }));
});
