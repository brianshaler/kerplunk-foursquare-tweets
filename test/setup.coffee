path = require 'path'
global.Should = require 'should'

models = {}

before ->
  @System =
    registerModel: (name, model) ->
      models[name] = model
    getModel: (name) ->
      models[name]
  @fixturePath = (pathname) ->
    path.join __dirname, 'fixtures', pathname
  @fixture = (pathname) ->
    require path.join __dirname, 'fixtures', pathname
