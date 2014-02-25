## Auto Merger

Streaming ETL

[![Build Status](https://travis-ci.org/Interlincx/automerger.png)](https://travis-ci.org/Interlincx/automerger)
[![NPM](https://nodei.co/npm/automerger.png)](https://nodei.co/npm/automerger/)


### Test

    bin/test

### Install

    npm install automerger

### Usage
    
    
    # setup 

    {EventEmitter}  = require "events"
    es              = require "event-stream"
    redis           = require "redis"
    AM              = require "automerger"

    conf = 
      db: 
        name: "test-model"
        find: (id, cb) -> cb null, null
        upsert: (id, doc, cb) -> cb null
      model: new EventEmitter
      redis: null
      sourceStream: es.through (data) -> @queue data
      sourceToIdPieces: (doc) -> [doc.type, doc.field]
      subscriptions: [
        ["dest1"]
        [
          "filtered-sub"
          (doc) -> 
            allow = doc.type is "allowed"
            return allow
        ]
      ]
      schema: ["type", "field"]
      version: "test-version"

    am = new AM conf

    # input a source object

    sourceDoc = 
      current: {type: "none", field: "name"}

    am.sourceStream.write sourceDoc

    # observe output

    rc = redis.createClient()

    rc.blpop "dest1", (err, res) ->
      console.error if err
      queueName = res[0]
      inputForSubscriber = JSON.parse res[1]



    