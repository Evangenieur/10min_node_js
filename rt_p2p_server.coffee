Model = require "scuttlebutt/model"
es = require('event-stream')

model = new Model

app = require("express")()
server = require("http").createServer(app)

port = Number process.argv[2]

### HTTP P2P Server ###

app.put "/_replicate", (req, res) ->
  req.pipe(model.createStream()).pipe(res)

app.get "/", (req, res) ->
  res.send """
    <body>
      <textarea id="chat" cols="40" rows="5"></textarea>
      <div id="info"></div>
      <script src="/socket.io/socket.io.js"></script>
      <script>
        var chat = document.getElementById("chat"), 
          socket = io.connect("http://localhost:#{port}", {
              "reconnect": true,
              "reconnection delay": 500,
              "max reconnection attempts": 99999
            }),
          myself_emitted = false,
          info = document.getElementById("info");

        socket.on('connect', function() {
          info.innerHTML = "connected to #{port}";
        });
        socket.on('disconnect', function() {
          info.innerHTML = "disconnected";
        });

        socket.on('chat', function (data) {
          if (!myself_emitted) {
            chat.value = data;
          } 
          myself_emitted = false;
        });

        chat.addEventListener( "keyup",
          function(e) {
            myself_emitted = true;
            socket.emit("chat", chat.value)
          }
        );
      </script>
    </body>
  """

server.listen port
console.log "Listening on port #{port}"

request = require "request"
process.argv.slice(3).map(Number).forEach (peer_port) ->
  console.log "Replication to #{peer_port}"
  r = request.put "http://localhost:#{peer_port}/_replicate"
  r.pipe(model.createStream()).pipe(r)
  
### Socket.io ###
io = require("socket.io").listen(server)
io.set "log level", 0

io.sockets.on "connection", (socket) ->

  console.log "Connection"
  socket.emit "chat", model.get("chat")

  socket.on "chat", (v) ->
    console.log "chat", v
    model.set "chat", v

  model.createStream().pipe es.map (raw_data, cb) ->
    data = JSON.parse raw_data
    if (typeof data is "object") and data[0]?.length?
      [k, v] = data[0]
      if k is "chat"
        socket.emit "chat", v