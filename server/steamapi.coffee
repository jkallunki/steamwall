Curl       = require 'node-curl'
cheerio    = require 'cheerio'
_          = require 'lodash'
q          = require 'q'

module.exports =

  formProfileUrl: (userid, appid = 0) ->
    userid = encodeURIComponent userid
    url = 'http://steamcommunity.com/'
    url += if /^\d+$/.test userid then 'profiles' else 'id'
    url + '/' + userid + '/screenshots/?appid=' + appid + '&sort=newestfirst&browsefilter=myfiles&view=grid'

  formGameSearchUrl: (keyword) -> 
    keyword = encodeURIComponent keyword
    'http://store.steampowered.com/search/suggest?term=' + keyword + '&f=games&l=english'

  getScreenhotPageUrls: (userid, appid, callback) ->
    curl = Curl.create()
    curl @formProfileUrl(userid, appid), (err) ->
      urls = []
      unless err?
        $ = cheerio.load this.body
        urls = $('.profile_media_item').map(-> $(this).attr('href')).get()
      @close()
      callback urls

  getUserScreenshots: (userid, appid, callback) ->
    @getScreenhotPageUrls userid, appid, (urls) ->
      promises = _.map urls, (url) ->
        def = q.defer()
        curl = Curl.create()
        curl url, (err) ->
          if err?
            def.reject()
          else
            $ = cheerio.load this.body
            def.resolve
              src: $('#ActualMedia').parent().attr('href')
              author: $('.linkAuthor').find('a').text()
          @close()
        def.promise

      q.allSettled(promises).then (results) ->
        callback _.filter(results, (r) -> r.state == 'fulfilled').map((r) -> r.value)

  getScreenshots: (userids, appids, callback) ->
    promises = _.chain(userids).map((userid) =>
      _.map appids, (appid) =>
        def = q.defer()
        @getUserScreenshots userid, appid, (screenshots) ->
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
      curl @formGameSearchUrl(keyword), (err) ->
        data = []
        unless err?
          $ = cheerio.load this.body
          data = $('a').map(-> id: $(this).data('ds-appid'), title: $(this).find('.match_name').text()).get()
        @close()
        callback data
