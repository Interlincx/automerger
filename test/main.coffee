assert = require('chai').assert
{EventEmitter} = require 'events'

AutoMerger = require '../src/index'
getBasicConfig = require './fixtures/basic-config'
redis = require 'fakeredis'

describe 'AutoMerger', ->
  it 'should instantiate', ->
    minViableConfig =
      db:
        name: ''
      model: new EventEmitter
      sourceStream:
        pipe: ->
        resume: ->

    am = new AutoMerger minViableConfig
    assert.ok am

  it 'should push to subscribers', (done) ->

    conf = getBasicConfig()
    conf.redis = rc = redis.createClient()
    am = new AutoMerger conf


    sourceDoc =
      current: {type: 'none", field: "name'}

    am.sourceStream.write sourceDoc

    rc.blpop 'dest1', 0, (err, res) ->
      assert.isNull err

      queueName = res[0]
      assert.equal queueName, 'dest1'

      subJob = JSON.parse res[1]
      assert.equal subJob.action, 'create'
      assert.equal subJob.name, 'test-model'

      doc = subJob.current
      assert.equal doc._id, 'none!name'
      assert.ok doc.createdAt
      assert.equal doc.type, 'none'
      assert.equal doc.field, 'name'
      assert.equal doc.version, 'test-version'

      done()

  it 'should stop emitting after destroy', (done) ->
    conf = getBasicConfig()
    conf.redis = redis.createClient 'destroy-test'
    am = new AutoMerger conf

    am.destroy()

    sourceDoc =
      current: {type: 'none", field: "name'}

    am.sourceStream.write sourceDoc

    rc = redis.createClient 'destroy-test'

    rc.blpop 'dest1', 1, (err, res) ->
      assert.isNull err
      assert.isNull res

      assert.isFalse am.sourceStream.readable
      assert.isFalse am.sourceStream.writable

      assert.isFalse am.targetStream.readable
      assert.isFalse am.targetStream.writable

      done()
