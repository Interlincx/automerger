module.exports =
  stringToObject: (schema) ->
    targetKey: schema
    sourceValue: (source) -> source[schema]
    strategy: "assign"

  functionToObject: (schema) ->
    strategy: schema