{timestampPointers} = require "./basic"

linearSearch = (current, array) ->
  for value in array
    break if value[0] > current
    nextElement = value
  nextElement

binarySearch = (current, array) ->
  minIndex = 0
  maxIndex = array.length - 1
  loop
    if minIndex > maxIndex
      return nextElement
    currentIndex = (minIndex + maxIndex) / 2 | 0
    value = array[currentIndex]
    if value[0] <= current
      nextElement = value
      minIndex = currentIndex + 1
    else
      maxIndex = currentIndex - 1


for timestamp in [1..3600]
  lin = linearSearch(timestamp, timestampPointers)
  bin = binarySearch(timestamp, timestampPointers)
  if lin != bin
    console.log "#{lin} != #{bin} for #{timestamp}"


start = process.hrtime()

for i in [1..10000]
  for timestamp in [1..3600]
    linearSearch(timestamp, timestampPointers)

t = process.hrtime(start)
console.log('linear search took %d seconds', t[0] + t[1] / 1000000000);


start = process.hrtime()

for i in [1..10000]
  for timestamp in [1..3600]
    binarySearch(timestamp, timestampPointers)

t = process.hrtime(start)
console.log('binary search took %d seconds', t[0] + t[1] / 1000000000);
