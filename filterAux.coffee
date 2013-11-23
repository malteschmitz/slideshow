fs = require 'fs'
content = fs.readFileSync 'latex.aux', 'utf8'
lines = content.split '\n'
result = (line for line in lines when line.indexOf('sectionentry') > -1 or line.indexOf('subsectionentry') > -1)
console.log(result)