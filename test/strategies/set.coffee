assert = require("chai").assert
Strategies = require "../../src/strategies"

describe 'Set', ->
  it "no add", ->
    strategy = "set"
    opts =
      sourceValue: (source) -> source.val
      targetKey: "vals"
      target: {vals: ["a"]}
      current: {val: "a"}
      previous: {val: "a"}

    hasChanged = Strategies[strategy] opts
    assert.isFalse hasChanged

  it "add", ->
    strategy = "set"
    opts =
      sourceValue: (source) -> source.val
      targetKey: "vals"
      target: {vals: ["a"]}
      current: {val: "b"}
      previous: {val: "a"}

    hasChanged = Strategies[strategy] opts
    assert.isTrue hasChanged
    assert.deepEqual opts.target.vals, ["a", "b"]
