## Auto Merger

Streaming ETL

[![Build Status](https://travis-ci.org/Interlincx/automerger.png)](https://travis-ci.org/Interlincx/automerger)

[![NPM](https://nodei.co/npm/automerger.png)](https://nodei.co/npm/automerger/)


### Test

    npm test

### Install

    npm install automerger

### Usage

    # setup

    {EventEmitter}  = require "events"
    es              = require "event-stream"
    AM              = require "automerger"

    subscriber = es.through (job) ->
      console.log "job", job
      ###

      {
        action: 'updated',
        current: {...}, # the current version of the source document
        previous: {...} # the previous version of the source document
      }

      ###

    conf =
      db:
        name: "test-model"
        find: (id, cb) -> cb null, null
        upsert: (id, doc, cb) -> cb null
      model: new EventEmitter
      sourceStream: es.through (data) -> @queue data
      sourceToIdPieces: (doc) -> [doc.type, doc.field]
      subscriberStreams: [subscriber]

      schema: ["type", "field"]
      version: "test-version"

    am = new AM conf

    # input a source object

    sourceDoc =
      current: {type: "none", field: "name"}

    am.sourceStream.write sourceDoc

## config.sourceStream

a single readable stream which supplies source documents

## config.subscriberStreams

an array of one or more writable streams that want to be notified of updates to target documents

## config.schema

an array of fields that will be mapped to the target document from the source document. strings in the example schema above using the default strategy 'assign'. There are a number of other strategies to choose from

### on 'source-reject'

there are a few cases where a source document will be "rejected" and tagged unusable or irrelevant:
  1. a complete 'id' field cannot be built from the source document
  2. the source document did not change the current target document
  3. the source document failed an optional user-created 'rejectSource' function

it may be useful to act on source documents that are rejected. in those cases set up an `automerger.on 'source-reject'` event listener.

## config.readyProperties

may optionally pass an array of string properties that must exist on the *target* document in order to be deemed 'ready'. A document not being ready is different than a source being rejected. Rejected source documents will not be saved while the unready documents will. The difference is that subscribers are not told about documents that are not ready.

automerger instances emit `'target-not-ready'` events when a target fails the readiness requirements

## config.migrator

a migration is an optional user-defined function that is applied to existing documents as they come out of the database prior to being updated when new source documents arrive.

## config.alterSource

optional user-defined function to manipulate source documents in the worker as they arrive from the sourceStream





