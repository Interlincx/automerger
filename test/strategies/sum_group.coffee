Strategies = require '../../src/strategies'

describe 'Sum Group', ->
  it 'no change', ->
    opts =
      sourceValue: (source) -> source.val
      targetKey: 'val'
      target: {val: {clicks: 25, impressions: 50}}
      current: {val: {clicks: 1, impressions: 1}}
      previous: {val: {clicks: 1, impressions: 1}}

    hasChanged = Strategies.sum_group opts
    assert.isFalse hasChanged

  it 'change', ->
    opts =
      sourceValue: (source) -> source.val
      targetKey: 'val'
      target: {val: {clicks: 25, impressions: 50}}
      current: {val: {clicks: 2, impressions: 2}}
      previous: {val: {clicks: 1, impressions: 1}}

    hasChanged = Strategies.sum_group opts
    assert.isTrue hasChanged
    assert.equal opts.target.val.clicks, 26
