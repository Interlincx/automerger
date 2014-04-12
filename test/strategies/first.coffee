assert = require('chai').assert
Strategies = require '../../src/strategies'

describe 'First', ->
  it 'change', ->
    strategy = 'first'

    opts =
      sourceValue: (source) -> {ts: source.ts, date: source.date}
      targetKey: 'first_date'
      target: {_id: '1', first_date: {ts: 153, date: '2012-02-02'}}
      current: {ts: 123, date: '2012-02-01'}
      previous: {ts: 153, date: '2012-02-02'}

    hasChanged = Strategies[strategy] opts

    assert.isTrue hasChanged
    assert.deepEqual opts.target, {_id: '1', first_date: {ts: 123, date: '2012-02-01'}}

  it 'no change', ->
    strategy = 'first'

    opts =
      sourceValue: (source) -> {ts: source.ts, date: source.date}
      targetKey: 'first_date'
      target: {_id: '1', first_date: {ts: 153, date: '2012-02-02'}}
      current: {ts: 153, date: '2012-02-02'}
      previous: {ts: 153, date: '2012-02-02'}

    hasChanged = Strategies[strategy] opts

    assert.isFalse hasChanged
    assert.deepEqual opts.target, {_id: '1', first_date: {ts: 153, date: '2012-02-02'}}
