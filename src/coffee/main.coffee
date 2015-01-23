$   = require 'jquery'
ko  = require 'knockout'
qs  = require 'qs'
_   = require 'lodash'

ko.bindingHandlers.slideshow=
  init: (element, valueAccessor, allBindings, viewModel, bindingContext) ->

    updateImage = ->
      images = ko.unwrap(valueAccessor())
      if images.length > 0
        src = (_.sample(images)).src
        console.log src
        $(element).css 'background-image', 'url('+src+')'

    updateImage()
    setInterval updateImage, 5000
    

class ScreenshotViewModel
  constructor: ->
    @src = ko.observable()
    @user = ko.observable()

class AppViewModel
  constructor: (config) ->
    @configVisible  = ko.observable false
    @players        = ko.observableArray config.players
    @games          = ko.observableArray config.games

    @playerInput    = ko.observable ''
    @gameInput      = ko.observable ''

    @currentImage   = ko.observable null

    @screenshots    = ko.observableArray []

  toggleConfig: =>
    @configVisible !@configVisible()

  addPlayer: =>
    unless @players.indexOf(@playerInput()) >= 0
      @players.push @playerInput() 
      @playerInput ''

  removePlayer: (player) =>
    @players.remove player

  addGame: =>
    unless @games.indexOf(@gameInput()) >= 0
      @games.push @gameInput() 
      @gameInput ''

  removeGame: (game) =>
    @games.remove game

  applyChanges: =>
    localStorage.setItem 'config', JSON.stringify({
      players: @players()
      games: @games()
    })
    params =
      userids: @players()
      appids: @games()
    $.getJSON '/data', params, (data) =>
      console.log data

      if data.length > 0
        @screenshots data

$ ->
  savedConfig = JSON.parse localStorage.getItem('config')
  vmo = new AppViewModel savedConfig
  ko.applyBindings vmo