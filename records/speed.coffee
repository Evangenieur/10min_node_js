[file, mult] = process.argv[-2..-1]
console.log "#{file} * #{mult}"
fs = require "fs"
arr = JSON.parse fs.readFileSync(file).toString()
try
  for elem in arr
    elem.at = Math.floor elem.at * mult
  fs.writeFileSync file, JSON.stringify(arr)


