Strategies = require '../../src/strategies'

describe 'Target Assign', ->
  it 'merge hasChanged', ->
    strategy = 'target_assign'
    opts =
      targetValue: (target) -> target.pixels?.length or 0
      targetKey: 'pixel_count'
      target: {_id: '1', pixels: ['cld', 'rpt'], pixel_count: 1}
      current: {}
      previous: null

    hasChanged = Strategies[strategy] opts
    assert.isTrue hasChanged
    assert.deepEqual opts.target, {_id: '1', pixels: ['cld', 'rpt'], pixel_count: 2}

  it 'merge no change', ->
    strategy = 'target_assign'
    opts =
      targetValue: (target) -> target.pixels?.length or 0
      targetKey: 'pixel_count'
      target: {_id: '1', pixels: ['cld', 'rpt'], pixel_count: 2}
      current: {}
      previous: null

    hasChanged = Strategies[strategy] opts
    assert.isFalse hasChanged
    assert.deepEqual opts.target, {_id: '1', pixels: ['cld', 'rpt'], pixel_count: 2}

  it 'merge empty', ->
    strategy = 'target_assign'
    opts =
      targetValue: (target) -> target.pixels?.length or 0
      targetKey: 'pixel_count'
      target: {_id: '1'}
      current: {}
      previous: null

    hasChanged = Strategies[strategy] opts
    assert.isTrue hasChanged
    assert.deepEqual opts.target, {_id: '1', pixel_count: 0}
