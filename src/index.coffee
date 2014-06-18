_ = require 'underscore'
deepExtend = require 'deep-extend'
es = require 'event-stream'

schema = require './schema'
strategies = require './strategies'

class AutoMerger
  constructor: (opts) ->

    @db = opts.db
    @model = opts.model
    @sourceStream = opts.sourceStream

    @migrator = opts.migrator

    @sourceToIdPieces = opts.sourceToIdPieces
    @schema = opts.schema
    @readyProperties = opts.readyProperties or []

    @rejectSource = opts.rejectSource
    @alterSource = opts.alterSource
    @subscriberStreams = opts.subscriberStreams or []
    @parallel = opts.parallel
    @version = opts.version

    @saveStream = es.map @worker.bind this

    for subStream in @subscriberStreams
      @saveStream.pipe subStream

    @sourceStream.pipe @saveStream
    @sourceStream.resume()

  destroy: ->
    @model.removeAllListeners()
    @targetStream.destroy()
    @sourceStream.destroy()
    @redis.quit()

  getStrategy: (item) ->
    if typeof item.strategy is "function"
      strategy = item.strategy
    else
      strategy = strategies[item.strategy]

    return strategy

  getTargetKey: (item, current) ->
    if typeof item.targetKey is "function"
      targetKey = item.targetKey current
    else
      targetKey = item.targetKey

    return targetKey

  runStrategyWithTargetKey: (strategyOpts, targetKey, target, strategy) ->
    namePieces = targetKey.split "."
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

  mergeItem: (item, current, previous, target) ->
    if typeof item is "string"
      item = schema.stringToObject item
    else if typeof item is "function"
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

  merge: (opts) ->
    {curSource, prevSource, target} = opts

    targetChanged = false

    for item in @schema
      changed = @mergeItem item, curSource, prevSource, target

      targetChanged = true if changed

    return targetChanged

  getTargets: (id, callback) ->
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

  save: (curTarget, callback) ->

    curTarget.version = @version

    if curTarget.createdAt? and typeof curTarget.createdAt is "string"
      curTarget.createdAt = new Date(curTarget.createdAt)

    if curTarget.updatedAt? and typeof curTarget.updatedAt is "string"
      curTarget.updatedAt = new Date(curTarget.updatedAt)

    @db.upsert curTarget._id, curTarget, callback

  piecesToId: (pieces) ->
    valid = true
    for piece in pieces
      valid = false unless piece?

    return null unless valid

    key = pieces.join "!"
    return key

  checkIsReady: (target) ->
    ready = true
    for prop in @readyProperties
      ready = false unless target[prop]?

    return ready

  getAction: (curTarget, prevTarget) ->
    action = if prevTarget then 'update' else 'create'

    if @readyProperties?.length > 1
      curReady = @checkIsReady curTarget
      prevReady = @checkIsReady prevTarget if prevTarget?

      if curReady
        if prevReady
          action = "update"
        else
          action = "create"
      else
        action = "not_ready"

    return action

  worker: (sources, callback) ->
    self = this
    {current, previous} = sources
    curSource = current
    prevSource = previous

    if @rejectSource?
      if @rejectSource curSource
        callback()
        return @model.emit "reject", curSource

    @alterSource curSource if @alterSource?

    idPieces = @sourceToIdPieces curSource
    id = @piecesToId idPieces

    unless id?
      callback()
      return @model.emit "reject", curSource

    @getTargets id, (err, curTarget, prevTarget) ->

      mergeOpts =
        target: curTarget
        curSource: curSource
        prevSource: prevSource

      targetChanged = self.merge mergeOpts

      if targetChanged
        model = self.model
        action = self.getAction curTarget, prevTarget

        self.save curTarget, (err) ->
          return callback err if err

          if action is 'not_ready'
            # save but do not tell subscribers
            return callback()

          callback null,
            action: action
            current: curTarget
            previous: prevTarget
            name: self.db.name

      else
        self.model.emit "reject", curSource
        callback()

module.exports = AutoMerger
