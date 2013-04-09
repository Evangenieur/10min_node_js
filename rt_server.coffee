app = require("express")()
server = require("http").createServer(app)

port = Number process.argv[2]

### HTTP P2P Server ###

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

### Socket.io ###
io = require("socket.io").listen(server)
io.set "log level", 0

io.sockets.on "connection", (socket) ->

  console.log "Connection"

  socket.on "chat", (v) ->
    # Broadcast Chat
    io.of('').emit "chat", v

  