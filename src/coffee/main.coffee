$   = require 'jquery'
ko  = require 'knockout'
qs  = require 'qs'
_   = require 'lodash'

require './bindings.coffee'

class AppViewModel
  constructor: (config) ->
    @configVisible  = ko.observable false

    @players = ko.observableArray []
    @games   = ko.observableArray []

    @playerInput    = ko.observable ''
    @gameInput      = ko.observable ''
    @screenshots    = ko.observableArray []

    if config?
      if config.players? and config.players.length > 0
        @players config.players
      if config.games? and config.games.length > 0
        @games config.games
        @updateContent() if config.players? and config.players.length > 0


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
    @updateContent()

  updateContent: =>
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