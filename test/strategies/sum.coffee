assert = require('chai').assert
Strategies = require '../../src/strategies'

describe 'Sum', ->
  it 'no change', ->
    opts =
      sourceValue: (source) -> source.val
      targetKey: 'val'
      target: {val: 25}
      current: {val: 1}
      previous: {val: 1}

    hasChanged = Strategies.sum opts
    assert.isFalse hasChanged

  it 'change', ->
    opts =
      sourceValue: (source) -> source.val
      targetKey: 'val'
      target: {val: 25}
      current: {val: 2}
      previous: {val: 1}

    hasChanged = Strategies.sum opts

    assert.isTrue hasChanged
    assert.equal opts.target.val, 26
