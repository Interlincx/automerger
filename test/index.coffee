assert = require("chai").assert

AutoMerger = require "../src/index"
Strategies = require "../src/strategies"

describe "AutoMerger", ->
  describe "Class", ->
    
    args = 
      db: 
        name: ""
      model:
        emit: ->
      sourceStream:
        pipe: ->
        resume: ->

    am = new AutoMerger args
    assert.ok am

  describe "Strategies", ->

    it "assign primitive no change", ->
      opts = 
        sourceValue: (source) -> source.val
        targetKey: "tval"
        target: {tval: 1}
        current: {val: 1}

      hasChanged = Strategies.assign opts
      assert.isFalse hasChanged

    it "assign primitive with change", ->
      opts = 
        sourceValue: (source) -> source.val
        targetKey: "tval"
        target: {tval: 1}
        current: {val: 2}

      hasChanged = Strategies.assign opts
      assert.isTrue hasChanged

    it "assign object no change", ->
      opts = 
        sourceValue: (source) -> source.val
        targetKey: "val"
        target: {val: {a: [1,2,'a'], b: true}}
        current: {val: {a: [1,2,'a'], b: true}}

      hasChanged = Strategies.assign opts
      assert.isFalse hasChanged

    it "assign object with change", ->
      opts = 
        sourceValue: (source) -> source.val
        targetKey: "val"
        target: {val: {a: [1,2,'a'], b: true}}
        current: {val: {a: [1,2,'b'], b: true}}

      hasChanged = Strategies.assign opts
      assert.isTrue hasChanged

    it "sum no change", ->
      opts = 
        sourceValue: (source) -> source.val
        targetKey: "val"
        target: {val: 25}
        current: {val: 1}
        previous: {val: 1}

      hasChanged = Strategies.sum opts
      assert.isFalse hasChanged

    it "sum change", ->
      opts = 
        sourceValue: (source) -> source.val
        targetKey: "val"
        target: {val: 25}
        current: {val: 2}
        previous: {val: 1}

      hasChanged = Strategies.sum opts

      assert.isTrue hasChanged
      assert.equal opts.target.val, 26

    it "sum_group no change", ->
      opts = 
        sourceValue: (source) -> source.val
        targetKey: "val"
        target: {val: {clicks: 25, impressions: 50}}
        current: {val: {clicks: 1, impressions: 1}}
        previous: {val: {clicks: 1, impressions: 1}}

      hasChanged = Strategies.sum_group opts
      assert.isFalse hasChanged

    it "sum_group change", ->
      opts = 
        sourceValue: (source) -> source.val
        targetKey: "val"
        target: {val: {clicks: 25, impressions: 50}}
        current: {val: {clicks: 2, impressions: 2}}
        previous: {val: {clicks: 1, impressions: 1}}

      hasChanged = Strategies.sum_group opts
      assert.isTrue hasChanged
      assert.equal opts.target.val.clicks, 26

    it "max no change", ->
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

    it "max change", ->
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

    it "min no change", ->
      strategy = "min"
      opts = 
        sourceValue: (source) -> source.date
        targetKey: "min_date"
        target: {min_date: "2012-01-02"}
        current: {date: "2012-01-02"}
        previous: {date: "2012-01-02"}

      hasChanged = Strategies[strategy] opts
      assert.isFalse hasChanged
      assert.equal opts.target.min_date, "2012-01-02"

    it "min change", ->
      strategy = "min"
      opts = 
        sourceValue: (source) -> source.date
        targetKey: "min_date"
        target: {min_date: "2012-01-02"}
        current: {date: "2012-01-01"}
        previous: {date: "2012-01-02"}

      hasChanged = Strategies[strategy] opts
      assert.isTrue hasChanged
      assert.equal opts.target.min_date, "2012-01-01"

    it "set no add", ->
      strategy = "set"
      opts = 
        sourceValue: (source) -> source.val
        targetKey: "vals"
        target: {vals: ["a"]}
        current: {val: "a"}
        previous: {val: "a"}

      hasChanged = Strategies[strategy] opts
      assert.isFalse hasChanged

    it "set add", ->
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

    it "assign_group set new value", ->
      strategy = "assign_group"
      opts = 
        sourceValue: (source) -> source.product_properties
        targetKey: "product_properties"
        target: {_id: "1"}
        current: {product_properties: {tripped: true}}
        previous: null

      hasChanged = Strategies[strategy] opts
      assert.isTrue hasChanged
      assert.isTrue opts.target.product_properties.tripped

    it "assign_group merge", ->
      strategy = "assign_group"
      opts = 
        sourceValue: (source) -> source.product_properties
        targetKey: "product_properties"
        target: {_id: "1", product_properties: {isPhantom: false}}
        current: {product_properties: {tripped: true}}
        previous: null

      hasChanged = Strategies[strategy] opts
      assert.isTrue hasChanged
      assert.deepEqual opts.target.product_properties, {isPhantom: false, tripped: true}

    it "target_assign merge hasChanged", ->
      strategy = "target_assign"
      opts = 
        targetValue: (target) -> target.pixels?.length or 0
        targetKey: "pixel_count"
        target: {_id: "1", pixels: ['cld', 'rpt'], pixel_count: 1}
        current: {}
        previous: null

      hasChanged = Strategies[strategy] opts
      assert.isTrue hasChanged
      assert.deepEqual opts.target, {_id: "1", pixels: ['cld', 'rpt'], pixel_count: 2}

    it "target_assign merge no change", ->
      strategy = "target_assign"
      opts = 
        targetValue: (target) -> target.pixels?.length or 0
        targetKey: "pixel_count"
        target: {_id: "1", pixels: ['cld', 'rpt'], pixel_count: 2}
        current: {}
        previous: null

      hasChanged = Strategies[strategy] opts
      assert.isFalse hasChanged
      assert.deepEqual opts.target, {_id: "1", pixels: ['cld', 'rpt'], pixel_count: 2}
      
    it "target_assign merge empty", ->
      strategy = "target_assign"
      opts = 
        targetValue: (target) -> target.pixels?.length or 0
        targetKey: "pixel_count"
        target: {_id: "1"}
        current: {}
        previous: null

      hasChanged = Strategies[strategy] opts
      assert.isTrue hasChanged
      assert.deepEqual opts.target, {_id: "1", pixel_count: 0}

    it "first change", ->
      strategy = "first"

      opts = 
        sourceValue: (source) -> {ts: source.ts, date: source.date}
        targetKey: "first_date"
        target: {_id: "1", first_date: {ts: 153, date: "2012-02-02"}}
        current: {ts: 123, date: "2012-02-01"}
        previous: {ts: 153, date: "2012-02-02"}

      hasChanged = Strategies[strategy] opts

      assert.isTrue hasChanged
      assert.deepEqual opts.target, {_id: "1", first_date: {ts: 123, date: "2012-02-01"}}

    it "first no change", ->
      strategy = "first"

      opts = 
        sourceValue: (source) -> {ts: source.ts, date: source.date}
        targetKey: "first_date"
        target: {_id: "1", first_date: {ts: 153, date: "2012-02-02"}}
        current: {ts: 153, date: "2012-02-02"}
        previous: {ts: 153, date: "2012-02-02"}

      hasChanged = Strategies[strategy] opts

      assert.isFalse hasChanged
      assert.deepEqual opts.target, {_id: "1", first_date: {ts: 153, date: "2012-02-02"}}