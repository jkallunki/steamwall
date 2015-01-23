Curl       = require 'node-curl'
cheerio    = require 'cheerio'
_          = require 'lodash'
q          = require 'q'

module.exports =

  formProfileUrl: (userid, appid = 0) ->
    url = 'http://steamcommunity.com/'
    url += if /^\d+$/.test userid then 'profiles' else 'id'
    url + '/' + userid + '/screenshots/?appid=' + appid + '&sort=newestfirst&browsefilter=myfiles&view=grid'

  getScreenhotPageUrls: (userid, appid, callback) ->
    curl = Curl.create()
    curl @formProfileUrl(userid, appid), (err) ->
      $ = cheerio.load this.body
      @close()
      callback $('.profile_media_item').map(-> $(this).attr('href')).get()

  getUserScreenshots: (userid, appid, callback) ->
    @getScreenhotPageUrls userid, appid, (urls) ->
      promises = _.map urls, (url) ->
        def = q.defer()
        curl = Curl.create()
        curl url, (err) ->
          $ = cheerio.load this.body
          @close()
          def.resolve
            src: $('#ActualMedia').parent().attr('href')
            author: $('.linkAuthor').find('a').text()
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


