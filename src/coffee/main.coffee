$   = require 'jquery'
ko  = require 'knockout'

console.log 'foobar'

class ScreenshotViewModel
  constructor: ->
    @src = ko.observable()
    @user = ko.observable()

class AppViewModel
  constructor: ->
    @screenshots = ko.observableArray()

$ ->
  $.getJSON '/screenshots', (data) ->
    console.log data

    vmo = new AppViewModel()
    ko.applyBindings vmo