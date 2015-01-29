$   = require 'jquery'
ko  = require 'knockout'
qs  = require 'qs'
_   = require 'lodash'

require './bindings.coffee'

class AppViewModel
  constructor: (config) ->
    @configVisible  = ko.observable true

    @players = ko.observableArray []
    @games   = ko.observableArray []

    @playerInput    = ko.observable ''
    @gameInput      = ko.observable ''
    @saving         = ko.observable false
    @screenshots    = ko.observableArray []

    @gameInputOptions = ko.observableArray []
    ko.computed =>
      $.getJSON '/gamesearch', {keyword: @gameInput()}, (data) =>
        @gameInputOptions data

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
    gameId = parseInt @gameInput()
    unless isNaN(gameId) || _.find(@games(), (g) => gameId == g.id)
      @games.push {id: gameId}
    @gameInput ''

  chooseGameOption: (game) =>
    unless _.find(@games(), (g) -> game.id == g.id)
      @games.push game
    @gameInput ''

  removeGame: (game) =>
    @games.remove game

  applyChanges: =>
    unless @saving()
      localStorage.setItem 'config', JSON.stringify({
        players: @players()
        games: @games()
      })
      @updateContent()
      @saving true

  updateContent: =>
    params =
      userids: @players()
      appids: _.map @games(), (g) -> g.id
    $.getJSON '/data', params, (data) =>
      if data.length > 0
        @screenshots data
        @saving false

$ ->
  savedConfig = JSON.parse localStorage.getItem('config')
  vmo = new AppViewModel savedConfig
  ko.applyBindings vmo
