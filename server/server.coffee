bodyParser = require 'body-parser'
express    = require 'express'
mongoose   = require 'mongoose'
path       = require 'path'
_          = require 'lodash'
q          = require 'q'

steam      = require './steamapi.coffee'

DATABASE = 'mongodb://localhost/steamwall'

app = express()

app.use express.static path.join __dirname, '../', 'public'
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: false)

mongoose.connect DATABASE

if process.env.NODE_ENV == 'production'
  app.use express.logger()
  app.set 'json spaces', 0

screenshot = mongoose.model 'Screenshot',
  src: String
  user: String

app.get '/screenshots', (req, res) ->
  screenshot.find {}, (err, screenshots) ->
    console.log screenshots
    res.send screenshots

app.get '/data', (req, res) ->

  #userids = ['d-tail', '76561198076596010']
  #appids  = ['221100', '33930']

  userids = req.query.userids
  appids = req.query.appids

  steam.getScreenshots userids, appids, (data) ->
    res.send data

app.listen 9001