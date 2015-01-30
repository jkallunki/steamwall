Curl       = require 'node-curl'
cheerio    = require 'cheerio'
_          = require 'lodash'
q          = require 'q'

# Selectors and attributes for screen scraping Steam pages:
SELECTORS =
  ACTUAL_MEDIA:       '#ActualMedia'
  PROFILE_MEDIA_ITEM: '.profile_media_item'
  GAME_TITLE:         '.match_name'
  AUTHOR:             '.linkAuthor'

APP_ID_ATTR = 'ds-appid'

# Private helper methods:
getUrl = (url) ->
  def = q.defer()
  curl = Curl.create()
  curl url, (err) ->
    if err? then def.reject() else def.resolve @body
    @close()
  def.promise

formProfileUrl = (userid, appid = 0) ->
  userid = encodeURIComponent userid
  url = 'http://steamcommunity.com/'
  url += if /^\d+$/.test userid then 'profiles' else 'id'
  url + '/' + userid + '/screenshots/?appid=' + appid + '&sort=newestfirst&browsefilter=myfiles&view=grid'

formGameSearchUrl = (keyword) -> 
  keyword = encodeURIComponent keyword
  'http://store.steampowered.com/search/suggest?term=' + keyword + '&f=games&l=english'

onlyFulfilled = (results) ->
  _.filter(results, (r) -> r.state == 'fulfilled')

getScreenhotPageUrls = (userid, appid) ->
  def = q.defer()
  getUrl(formProfileUrl userid, appid).then (html) ->
    $ = cheerio.load html
    urls = $(SELECTORS.PROFILE_MEDIA_ITEM).map(-> $(this).attr 'href').get()
    def.resolve urls
  def.promise

getUserScreenshots = (userid, appid) ->
  allDef = q.defer()
  getScreenhotPageUrls(userid, appid).then (urls) =>
    promises = _.map urls, (url) =>
      def = q.defer()
      getUrl(url).then (html) ->
        $ = cheerio.load html
        def.resolve
          src: $(SELECTORS.ACTUAL_MEDIA).parent().attr 'href'
          author: $(SELECTORS.AUTHOR).find('a').text()
      def.promise
    q.allSettled(promises).then (results) ->
      allDef.resolve onlyFulfilled(results).map (r) -> r.value
  allDef.promise

# Public API:
module.exports =
  getScreenshots: (userids, appids, callback) ->
    promises = _.chain(userids).map((userid) =>
      _.map appids, (appid) =>
        def = q.defer()
        getUserScreenshots(userid, appid).then (screenshots) ->
          def.resolve screenshots
        def.promise
    ).flatten().value()
    q.allSettled(promises).then (results) ->
      callback _.chain(onlyFulfilled(results)).map((r) -> r.value).flatten().value()

  getGameSearch: (keyword, callback) ->
    keyword = keyword.trim()
    if keyword.length == 0
      callback []
    else
      getUrl(formGameSearchUrl keyword).then (html) ->
        $ = cheerio.load html
        data = $('a').map(-> id: $(this).data(APP_ID_ATTR), title: $(this).find(SELECTORS.GAME_TITLE).text()).get()
        callback data
