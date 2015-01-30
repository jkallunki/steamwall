Curl       = require 'node-curl'
cheerio    = require 'cheerio'
_          = require 'lodash'
q          = require 'q'

module.exports =
  getUrl: (url) ->
    def = q.defer()
    curl = Curl.create()
    curl url, (err) ->
      if err?
        def.reject()
      else
        def.resolve @body
      @close()
    def.promise

  formProfileUrl: (userid, appid = 0) ->
    userid = encodeURIComponent userid
    url = 'http://steamcommunity.com/'
    url += if /^\d+$/.test userid then 'profiles' else 'id'
    url + '/' + userid + '/screenshots/?appid=' + appid + '&sort=newestfirst&browsefilter=myfiles&view=grid'

  formGameSearchUrl: (keyword) -> 
    keyword = encodeURIComponent keyword
    'http://store.steampowered.com/search/suggest?term=' + keyword + '&f=games&l=english'

  getScreenhotPageUrls: (userid, appid) ->
    def = q.defer()
    @getUrl(@formProfileUrl(userid, appid)).then (html) ->
      $ = cheerio.load html
      urls = $('.profile_media_item').map(-> $(this).attr('href')).get()
      def.resolve urls
    def.promise

  getUserScreenshots: (userid, appid) ->
    allDef = q.defer()
    @getScreenhotPageUrls(userid, appid).then (urls) =>
      promises = _.map urls, (url) =>
        def = q.defer()
        @getUrl(url).then (html) ->
          $ = cheerio.load html
          def.resolve
            src: $('#ActualMedia').parent().attr('href')
            author: $('.linkAuthor').find('a').text()
        def.promise
      q.allSettled(promises).then (results) ->
        allDef.resolve _.filter(results, (r) -> r.state == 'fulfilled').map((r) -> r.value)
    allDef.promise

  getScreenshots: (userids, appids, callback) ->
    promises = _.chain(userids).map((userid) =>
      _.map appids, (appid) =>
        def = q.defer()
        @getUserScreenshots(userid, appid).then (screenshots) ->
          def.resolve screenshots
        def.promise
    ).flatten().value()

    q.allSettled(promises).then (results) ->
      callback _.chain(results).filter((r) -> r.state == 'fulfilled').map((r) -> r.value).flatten().value()

  getGameSearch: (keyword, callback) ->
    keyword = keyword.trim()
    if keyword.length == 0
      callback []
    else
      curl = Curl.create()
      @getUrl(@formGameSearchUrl(keyword)).then (html) ->
        $ = cheerio.load html
        data = $('a').map(-> id: $(this).data('ds-appid'), title: $(this).find('.match_name').text()).get()
        callback data
