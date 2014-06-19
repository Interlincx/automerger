test = require 'tape'
Strategies = require '../../src/strategies'

describe 'Assign', ->
  it 'primitive no change', ->
    opts =
      sourceValue: (source) -> source.val
      targetKey: 'tval'
      target: {tval: 1}
      current: {val: 1}

    hasChanged = Strategies.assign opts
    assert.isFalse hasChanged

  it 'primitive with change', ->

    opts =
      sourceValue: (source) -> source.val
      targetKey: 'tval'
      target: {tval: 1}
      current: {val: 2}

    hasChanged = Strategies.assign opts
    assert.isTrue hasChanged

  it 'object no change', ->
    opts =
      sourceValue: (source) -> source.val
      targetKey: 'val'
      target: {val: {a: [1,2,'a'], b: true}}
      current: {val: {a: [1,2,'a'], b: true}}

    hasChanged = Strategies.assign opts
    assert.isFalse hasChanged

  it 'object with change', ->
    opts =
      sourceValue: (source) -> source.val
      targetKey: 'val'
      target: {val: {a: [1,2,'a'], b: true}}
      current: {val: {a: [1,2,'b'], b: true}}

    hasChanged = Strategies.assign opts
    assert.isTrue hasChanged
