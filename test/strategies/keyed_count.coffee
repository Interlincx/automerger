Strategies = require '../../src/strategies'

describe 'Keyed Count', ->
  it 'new doc', ->
    strategy = 'keyed_count'
    opts =
      sourceValue: (src) -> src.inputName
      current: {inputName: 'firstName'}
      previous: undefined
      targetKey: 'inputName'
      target: { _id: '1' }

    hasChanged = Strategies[strategy] opts
    assert.isTrue hasChanged
    assert.deepEqual opts.target,
      _id: '1'
      inputName:
        firstName: 1

  it 'update', ->
    strategy = 'keyed_count'
    opts =
      sourceValue: (src) -> src.inputName
      current: {inputName: 'firstName'}
      targetKey: 'inputName'
      previous: undefined
      target:
        _id: '1'
        inputName:
          firstName: 1

    hasChanged = Strategies[strategy] opts
    assert.isTrue hasChanged
    assert.deepEqual opts.target,
      _id: '1'
      inputName:
        firstName: 2

  it 'change', ->
    strategy = 'keyed_count'
    opts =
      sourceValue: (src) -> src.inputName
      current: {inputName: 'firstName'}
      targetKey: 'inputName'
      previous: {inputName: 'lastName'}
      target:
        _id: '1'
        inputName:
          lastName: 2

    hasChanged = Strategies[strategy] opts
    assert.isTrue hasChanged
    assert.deepEqual opts.target,
      _id: '1'
      inputName:
        lastName: 1
        firstName: 1
