bodyParser = require 'body-parser'
express    = require 'express'
path       = require 'path'
_          = require 'lodash'
q          = require 'q'

steam      = require './steamapi.coffee'

app = express()

app.use express.static path.join __dirname, '../', 'public'
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: false)

if process.env.NODE_ENV == 'production'
  app.use express.logger()
  app.set 'json spaces', 0

app.get '/gamesearch', (req, res) ->
  keyword = req.query.keyword
  steam.getGameSearch keyword, (data) ->
    res.send data

app.get '/data', (req, res) ->
  userids = req.query.userids
  appids = req.query.appids
  steam.getScreenshots userids, appids, (data) ->
    res.send data

app.listen 9001
