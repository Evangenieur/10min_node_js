Model = require "scuttlebutt/model"

model = new Model

app = require("express")()
server = require("http").createServer(app)

### HTTP P2P Server ###

app.put "/_replicate", (req, res) ->
  console.log "replication req"
  req.pipe(model.createStream()).pipe(res)

app.get "/", (req, res) ->
  console.log req.query
  res.send (
    for k, v of req.query
      ret = {}
      if v 
        model.set k, v
      ret[k] = model.get k
      ret
  )

app.listen Number port = process.argv[2]
console.log "Listening on port #{port}"

request = require "request"
process.argv.slice(3).map(Number).forEach (peer_port) ->
  console.log "Replication to #{peer_port}"
  r = request.put "http://localhost:#{peer_port}/_replicate"
  r.pipe(model.createStream()).pipe(r)
  
