{EventEmitter}  = require 'events'
util            = require 'util'

deepExtend = require 'deep-extend'
es = require 'event-stream'
async = require 'async'


schema = require './schema'
strategies = require './strategies'

module.exports = AutoMerger = (opts) ->
  unless this instanceof AutoMerger
    return new AutoMerger opts

  EventEmitter.call this

  optKeys = [
    'alterSource', 'db', 'migrator'
    'readyProperties', 'rejectSource', 'schema'
    'sourceStream', 'sourceToIdPieces'
    'subscriberQueues', 'version', 'destroyHook'
  ]

  @subscriberQueues ?= []

  for key in optKeys
    this[key] = opts[key] if opts[key]

  @workerStream = es.map @worker.bind this
  @sourceStream.pipe @workerStream

  return this

util.inherits AutoMerger, EventEmitter

AutoMerger::getStrategy = (item) ->
  if typeof item.strategy is 'function'
    strategy = item.strategy
  else
    strategy = strategies[item.strategy]

  return strategy

AutoMerger::getTargetKey = (item, current) ->
  if typeof item.targetKey is 'function'
    targetKey = item.targetKey current
  else
    targetKey = item.targetKey

  return targetKey

AutoMerger::runStrategyWithTargetKey = (strategyOpts, targetKey, target, strategy) ->
  namePieces = targetKey.split '.'
  strategyOpts.targetKey = targetKey

  if namePieces.length is 1
    strategyOpts.target = target

    strategy strategyOpts

  else if namePieces.length is 2
    strategyOpts.targetKey = namePieces[1]
    location = namePieces[0]

    target[location] ?= {}
    strategyOpts.target = target[location]

    strategy strategyOpts

AutoMerger::mergeItem = (item, current, previous, target) ->
  if typeof item is 'string'
    item = schema.stringToObject item
  else if typeof item is 'function'
    item = schema.functionToObject item

  strategyOpts =
    sourceValue: item.sourceValue
    targetValue: item.targetValue
    current: current
    previous: previous

  strategy = @getStrategy item
  targetKey = @getTargetKey item, current

  if targetKey?
    @runStrategyWithTargetKey strategyOpts, targetKey, target, strategy

  else

    strategyOpts.target = target
    strategy strategyOpts

AutoMerger::merge = (opts) ->
  {curSource, prevSource, target} = opts

  targetChanged = false

  for item in @schema
    changed = @mergeItem item, curSource, prevSource, target

    targetChanged = true if changed

  return targetChanged

AutoMerger::getTargets = (id, callback) ->
  self = this
  @db.find id, (err, doc) ->

    if doc
      doc = self.migrator doc if self.migrator
      prevTarget = deepExtend {}, doc
      doc.updatedAt = new Date
      curTarget = doc
    else
      prevTarget = null
      curTarget = {_id: id, createdAt: new Date}

    callback err, curTarget, prevTarget

AutoMerger::save = (curTarget, callback) ->
  @db.upsert curTarget._id, curTarget, callback

AutoMerger::piecesToId = (pieces) ->
  valid = true
  for piece in pieces
    valid = false unless piece?

  return null unless valid

  key = pieces.join '!'
  return key

AutoMerger::checkIsReady = (target) ->
  return true unless @readyProperties?

  ready = true
  for prop in @readyProperties
    ready = false unless target[prop]?

  return ready

AutoMerger::getAction = (curTarget, prevTarget) ->
  action = if prevTarget then 'update' else 'create'

  if @readyProperties?
    curReady = @checkIsReady curTarget
    prevReady = @checkIsReady prevTarget if prevTarget?

    if curReady
      if prevReady
        action = 'update'
      else
        action = 'create'
    else
      action = 'target-not-ready'

  return action

AutoMerger::setStampVersion = (doc) ->
  doc.version = @version

  if doc.createdAt? and typeof doc.createdAt is 'string'
    doc.createdAt = new Date(doc.createdAt)

  if doc.updatedAt? and typeof doc.updatedAt is 'string'
    doc.updatedAt = new Date(doc.updatedAt)

AutoMerger::worker = (sources, callback) ->
  self = this
  {current, previous} = sources
  curSource = current
  prevSource = previous

  origCallback = callback
  callback = (args...) ->
    self.sourceStream.write sources.cbId
    origCallback.apply null, args

  if @rejectSource?
    if @rejectSource curSource
      callback()
      return @emit 'source-reject', curSource

  @alterSource curSource if @alterSource?

  idPieces = @sourceToIdPieces curSource
  id = @piecesToId idPieces

  unless id?
    @emit 'source-reject', curSource
    return callback()

  @getTargets id, (err, curTarget, prevTarget) ->

    mergeOpts =
      target: curTarget
      curSource: curSource
      prevSource: prevSource

    targetChanged = self.merge mergeOpts

    if !targetChanged
      self.emit 'source-reject', curSource
      return callback()

    model = self.model
    action = self.getAction curTarget, prevTarget

    self.setStampVersion curTarget

    if action is 'target-not-ready'
      return self.save curTarget, (err) ->
        self.emit action, curTarget
        callback err

    if self.subscriberQueues.length is 0
      return self.save curTarget, callback

    subMsg =
      action: action
      current: curTarget
      previous: prevTarget
      name: self.db.name

    async.each self.subscriberQueues, (queue, cb) ->
      queue.push subMsg, cb

    , (err) ->
      return callback err if err
      self.save curTarget, callback

AutoMerger::close = -> @sourceStream.emit 'end'
