Strategies = require '../../src/strategies'

describe 'Assign Group', ->

  it 'set new value', ->
    strategy = 'assign_group'
    opts =
      sourceValue: (source) -> source.product_properties
      targetKey: 'product_properties'
      target: {_id: '1'}
      current: {product_properties: {tripped: true}}
      previous: null

    hasChanged = Strategies[strategy] opts
    assert.isTrue hasChanged
    assert.isTrue opts.target.product_properties.tripped

  it 'merge', ->
    strategy = 'assign_group'
    opts =
      sourceValue: (source) -> source.product_properties
      targetKey: 'product_properties'
      target: {_id: '1', product_properties: {isPhantom: false}}
      current: {product_properties: {tripped: true}}
      previous: null

    hasChanged = Strategies[strategy] opts
    assert.isTrue hasChanged
    assert.deepEqual opts.target.product_properties, {isPhantom: false, tripped: true}
