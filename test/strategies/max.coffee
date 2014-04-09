assert = require("chai").assert
Strategies = require "../../src/strategies"

describe 'Max', ->
  it "no change", ->
    strategy = "max"
    opts =
      sourceValue: (source) -> source.date
      targetKey: "max_date"
      target: {max_date: "2012-01-01"}
      current: {date: "2012-01-01"}
      previous: {date: "2012-01-01"}

    hasChanged = Strategies[strategy] opts
    assert.isFalse hasChanged
    assert.equal opts.target.max_date, "2012-01-01"

  it "change", ->
    strategy = "max"
    opts =
      sourceValue: (source) -> source.date
      targetKey: "max_date"
      target: {max_date: "2012-01-01"}
      current: {date: "2012-01-02"}
      previous: {date: "2012-01-01"}

    hasChanged = Strategies[strategy] opts
    assert.isTrue hasChanged
    assert.equal opts.target.max_date, "2012-01-02"
