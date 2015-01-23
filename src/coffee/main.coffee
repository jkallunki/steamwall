$   = require 'jquery'
ko  = require 'knockout'
qs  = require 'qs'
_   = require 'lodash'

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
        @currentImage _.sample(data)

$ ->
  savedConfig = JSON.parse localStorage.getItem('config')
  vmo = new AppViewModel savedConfig
  ko.applyBindings vmo