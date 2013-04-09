require("colors");
console.log("Coucou from module".red);
console.log(arguments.callee.toString().yellow);
module.exports = function() { return { test: "coucou" } };
