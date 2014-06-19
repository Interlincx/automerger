test = require 'tape'
Strategies = require '../../src/strategies'

test 'Assign: primitive no change', (t)->
  opts =
    sourceValue: (source) -> source.val
    targetKey: 'tval'
    target: {tval: 1}
    current: {val: 1}

  hasChanged = Strategies.assign opts
  t.notOk hasChanged
  t.end()

test 'Assign: primitive with change', (t) ->

  opts =
    sourceValue: (source) -> source.val
    targetKey: 'tval'
    target: {tval: 1}
    current: {val: 2}

  hasChanged = Strategies.assign opts
  t.ok hasChanged
  t.end()

test 'Assign: object no change', (t) ->
  opts =
    sourceValue: (source) -> source.val
    targetKey: 'val'
    target: {val: {a: [1,2,'a'], b: true}}
    current: {val: {a: [1,2,'a'], b: true}}

  hasChanged = Strategies.assign opts
  t.notOk hasChanged
  t.end()

test 'Assign: object with change', (t) ->
  opts =
    sourceValue: (source) -> source.val
    targetKey: 'val'
    target: {val: {a: [1,2,'a'], b: true}}
    current: {val: {a: [1,2,'b'], b: true}}

  hasChanged = Strategies.assign opts
  t.ok hasChanged
  t.end()
