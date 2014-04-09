_          = require "underscore"

assign = (opts) ->
  {sourceValue, targetKey, target, current} = opts
  changed = false

  value = sourceValue current
  if value?
    orig = target[targetKey]
    target[targetKey] = value 


    if typeof value is "object" 
      unless _.isEqual orig, value
        changed = true

    else
      if target[targetKey] isnt orig
        changed = true

  return changed

# caveat: with a nested targetKey passed to auto_merger, both targetKey and target will be zoomed in 1 level
target_assign = (opts) ->
  {targetValue, targetKey, target, current} = opts
  changed = false
  value = targetValue target
  if value?
    orig = target[targetKey]
    target[targetKey] = value 

    if typeof value is "object" 
      unless _.isEqual orig, value
        changed = true

    else
      if target[targetKey] isnt orig
        changed = true

  return changed

sum = (opts) ->
  {sourceValue, targetKey, target, current, previous} = opts
  changed = false

  curValue = (sourceValue current) or 0
  prevValue = sourceValue previous if previous?


  target[targetKey] ?= 0
  orig = target[targetKey]

  if prevValue?
    target[targetKey] -= prevValue
  target[targetKey] += curValue

  if target[targetKey] isnt orig
    changed = true

  return changed

sum_group = (opts) ->
  {sourceValue, targetKey, target, current, previous} = opts
  changed = false

  curGroup = (sourceValue current) or {}
  prevGroup = sourceValue previous if previous?
  
  tBase = target[targetKey] ?= {}

  for key, curVal of curGroup

    tBase[key] ?= 0
    orig = tBase[key]
    if prevGroup?
      tBase[key] -= prevGroup[key] if prevGroup[key]
    tBase[key] += curVal

    if orig isnt tBase[key]
      changed = true

  return changed

assign_group = (opts) ->
  {sourceValue, targetKey, target, current, previous} = opts
  changed = false

  curGroup = (sourceValue current) or {}
  prevGroup = sourceValue previous if previous?
  
  tBase = target[targetKey] ?= {}

  for key, curVal of curGroup

    orig = tBase[key]
    tBase[key] = curVal

    if orig isnt tBase[key]
      changed = true

  return changed

max = (opts) ->
  {sourceValue, targetKey, target, current, previous} = opts
  changed = false

  value = sourceValue current
  if value?
    target[targetKey] ?= value
    orig = target[targetKey]

    target[targetKey] = value if value > target[targetKey]

    if orig isnt target[targetKey]
      changed = true

  return changed

min = (opts) ->
  {sourceValue, targetKey, target, current, previous} = opts
  changed = false

  value = sourceValue current
  if value?
    target[targetKey] ?= value
    orig = target[targetKey]

    target[targetKey] = value if value < target[targetKey]

    if orig isnt target[targetKey]
      changed = true

  return changed

# sourceValue() must return {ts: 123456, ...}
first = (opts) ->
  {sourceValue, targetKey, target, current, previous} = opts
  changed = false

  value = sourceValue current
  if value?.ts?
    target[targetKey] ?= value
    orig = target[targetKey]

    target[targetKey] = value if value.ts < target[targetKey].ts

    if orig isnt target[targetKey]
      changed = true

  return changed

set = (opts) ->
  {sourceValue, targetKey, target, current, previous} = opts
  changed = false
  value = sourceValue current
  if value?
    target[targetKey] ?= []

    unless value in target[targetKey]
      target[targetKey].push value 
      changed = true

  return changed

keyed_count = (opts) ->
  {sourceValue, targetKey, target, current, previous} = opts
  changed = false

  currentVal = sourceValue current
  if previous and previous[targetKey]
    prevVal = sourceValue previous

  counts = target[targetKey] ?= {}

  if not previous?
    counts[currentVal] ?= 0
    counts[currentVal] += 1
    changed = true

  else if prevVal isnt currentVal
    counts[currentVal] ?= 0
    counts[currentVal] += 1

    counts[prevVal] ?= 1 if prevVal?
    counts[prevVal] -= 1 if prevVal?

    changed = true

  return changed

module.exports =
  assign: assign
  target_assign: target_assign
  sum: sum
  max: max
  min: min
  first: first
  sum_group: sum_group
  assign_group: assign_group
  set: set
  keyed_count: keyed_count
