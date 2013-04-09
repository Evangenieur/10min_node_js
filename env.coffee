DIR_TO_SERVE = __dirname + "/static"
RECORD_DIR = __dirname + "/records"

fs = require "fs"
_ = require "underscore"
spawn = require("child_process").spawn
cs2js = spawn "coffee", ["-cw", DIR_TO_SERVE]
glob = require("glob")

cs2js.stdout.on "data", (data)->
  console.log data.toString()
  _(app.io.sockets.sockets).each (socket, id) ->
    socket.disconnect()

tty = require "tty.js"
app = tty.createServer
  cwd: "."
  term:
    termName: "xterm"

Recorded = {}

glob "#{RECORD_DIR}/*.json", (err, files) ->
  for file in files
    Recorded[file.match(/\/([^\.\/]+).json/)[1]] = JSON.parse \
      fs.readFileSync(file).toString()


app.io.sockets.on "connection", (socket) ->
  console.log "Connected"
  socket.emit "records", Recorded
  socket.on "record", (name, data) ->
    console.log "Record #{name}", data
    Recorded[name] = data
    saveRecord name

app.listen(3000)

saveRecord = (record_name) ->
  filename = "#{RECORD_DIR}/#{record_name}.json"
  console.log "Storing in #{filename}"
  fs.writeFileSync filename, JSON.stringify Recorded[record_name]

process.on "exit", -> 
  console.log "EXIT"
  cleanExit()
