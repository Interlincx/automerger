Strategies = require '../../src/strategies'

describe 'Min', ->
  it 'min no change', ->
    strategy = 'min'
    opts =
      sourceValue: (source) -> source.date
      targetKey: 'min_date'
      target: {min_date: '2012-01-02'}
      current: {date: '2012-01-02'}
      previous: {date: '2012-01-02'}

    hasChanged = Strategies[strategy] opts
    assert.isFalse hasChanged
    assert.equal opts.target.min_date, '2012-01-02'

  it 'min change', ->
    strategy = 'min'
    opts =
      sourceValue: (source) -> source.date
      targetKey: 'min_date'
      target: {min_date: '2012-01-02'}
      current: {date: '2012-01-01'}
      previous: {date: '2012-01-02'}

    hasChanged = Strategies[strategy] opts
    assert.isTrue hasChanged
    assert.equal opts.target.min_date, '2012-01-01'
