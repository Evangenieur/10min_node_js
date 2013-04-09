var fs = require("fs");
require("colors");
var os = require("os");
Object.keys(os).forEach(function(prop) {
  console.log(prop.green);
  if (typeof os[prop] == "function") {
    console.log(os[prop]());
  }
});
