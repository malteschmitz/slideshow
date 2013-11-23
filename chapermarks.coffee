slides = [[0,1],[50.8,2]]

# timestamps sorted by pages
# number of the page is used as key and its timestamp as value
timestamps = [];
for value in slides
  old = timestamps[value[1]]
  if (old == undefined or old > value[0])
    timestamps[value[1]] = value[0]

toHHMMSS = (x) ->
  return undefined unless x?
  sec_num = parseFloat(x, 10)
  hours = Math.floor(sec_num / 3600)
  minutes = Math.floor((sec_num - (hours * 3600)) / 60)
  seconds = sec_num - (hours * 3600) - (minutes * 60)

  if (hours < 10)
    hours = "0" + hours
  if (minutes < 10)
    minutes = "0" + minutes
  seconds = seconds.toFixed(3)
  if (seconds < 10)
    seconds = "0" + seconds
  hours + ':' + minutes + ':' + seconds

fs = require 'fs'
content = fs.readFileSync 'latex.aux', 'utf8'
fix = (a) ->
  a.replace(/\\IeC \{\\"a\}/g, "ä").
  replace(/\\IeC \{\\"u\}/g, "ü").
  replace(/\\IeC \{\\ss \}/g, "ß").
  replace(/\\LaTeX  /g, "LaTeX").
  replace(/\\ /g, " ").
  replace(/\\BibTeX  /g, "BibTeX")
lines = content.split '\n'
result = []
for line in lines
  match = line.match /\\sectionentry \{(\d+)\}\{(.+?)\}\{(\d+)\}/
  if match?
    time = toHHMMSS(timestamps[+match[3]])
    result.push("#{time} #{match[1]} #{fix(match[2])}") if time?
  else
    match = line.match /\\beamer@subsectionentry \{\d+\}\{(\d+)\}\{(\d+)\}\{(\d+)\}\{(.+?)\}\}\\headcommand/
    if match?
      time = toHHMMSS(timestamps[+match[3]])
      result.push("#{time} #{match[1]}.#{match[2]} #{fix(match[4])}") if time?
console.log(result.join('\n'))