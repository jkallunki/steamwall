bodyParser = require 'body-parser'
express    = require 'express'
mongoose   = require 'mongoose'
path       = require 'path'
Curl       = require 'node-curl'
cheerio    = require 'cheerio'
_          = require 'lodash'
q          = require 'q'

DATABASE = 'mongodb://localhost/steamwall'

app = express()

app.use express.static path.join __dirname, '../', 'public'
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: false)

mongoose.connect DATABASE

if process.env.NODE_ENV == 'production'
  app.use express.logger()
  app.set 'json spaces', 0

# Controllers
#require('./controllers/fruit') app

formProfileUrl = (userid) ->
  url = 'http://steamcommunity.com/'
  url += if /^\d+$/.test userid then 'profiles' else 'id'
  url + '/' + userid + '/screenshots/?appid=0&sort=newestfirst&browsefilter=myfiles&view=grid'

getScreenhotPageUrls = (userid, callback) ->
  curl = Curl.create()
  curl formProfileUrl(userid), (err) ->
    $ = cheerio.load this.body
    this.close()
    callback $('.profile_media_item').map(-> $(this).attr('href')).get()

getUserScreenshots = (userid, callback) ->
  getScreenhotPageUrls userid, (urls) ->
    promises = _.map urls, (url) ->
      def = q.defer()
      curl = Curl.create()
      curl url, (err) ->
        $ = cheerio.load this.body
        this.close()
        def.resolve
          src: $('#ActualMedia').parent().attr('href')
          author: $('.linkAuthor').find('a').text()
      def.promise

    q.allSettled(promises).then (results) ->
      console.log results
      callback _.filter(results, (r) -> r.state == 'fulfilled').map((r) -> r.value)

screenshot = mongoose.model 'Screenshot',
  src: String
  user: String

app.get '/screenshots', (req, res) ->
  screenshot.find {}, (err, screenshots) ->
    console.log screenshots
    res.send screenshots

app.get '/data', (req, res) ->
  #76561198076596010
  getUserScreenshots 'd-tail', (data) ->
    res.send data

app.listen 9001