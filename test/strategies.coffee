assert = require('chai').assert
Strategies = require '../src/strategies'

describe 'Strategies', ->
  require './strategies/assign'
  require './strategies/sum'
  require './strategies/sum_group'
  require './strategies/max'
  require './strategies/min'
  require './strategies/set'
  require './strategies/assign_group'
  require './strategies/target_assign'
  require './strategies/first'
  require './strategies/keyed_count'
