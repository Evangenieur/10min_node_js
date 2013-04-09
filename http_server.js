var express = require("express"),
  app = express()

app.get("/", function(req, res) {
  res.send("coucou");
});

app.listen(3500);
console.log("Listening on port 3500");
