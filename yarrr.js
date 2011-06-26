#!/usr/bin/env node

require('batteries').extendNative()

var fs = require('fs')
  , http = require('http')
  , join = require('path').join
  , notify = require('growl').notify
  , Downloads = join(process.env.HOME, 'Downloads')
  , created = JSON.parse(process.env.WATCH_CREATED)
  , torrents = created.grep(/\.torrent$/i)
  , skipped = []
  , _log = []
  , log = function(s) { s = '>>> ' + s; _log.push(s); console.log(s) }
  , err = function(s) { s = '!!! ' + s; _log.push(s); console.error(s) }
  , writeLog = function() { fs.writeFileSync('/Users/sjs/log/yarrr.log', _log.join('\n')) }

process.on('uncaughtException', function(e) {
  err('error: ' + e)
  err('bailing')
  process.exit(1)
})

torrents.forEach(function(torrent, i) {
  log(torrent)
  var path = join(Downloads, torrent)
  try {
    fs.statSync(path)
  }
  catch (e) {
    skipped.push(torrent)
    err(path + ' does not exist, skipping')
    return
  }
  var boundary = '48940923YARRRPIRATE3890457293'
    , torrentData = fs.readFileSync(path, 'binary')
    , torrentSize = torrentData.length
    , data = [ '--' + boundary
             , 'Content-Disposition: form-data; name="torrent_file"; filename="' + torrent + '"'
             , 'Content-Type: application/x-bittorrent'
             , ''
             , torrentData
             , '--' + boundary + '--\r\n'
             ].join('\r\n')
    , opts = {
        method: 'POST',
        host: 'h.samhuri.net',
        port: 8080,
        path: '/gui/?action=add-file',
        headers: { 'Authorization': 'Basic YWRtaW46YWRtaW4='
                 , 'Content-Type': 'multipart/form-data; boundary=' + boundary
                 , 'Content-Length': data.length
                 }
      }
    , req = http.request(opts, function(res) {
        var responseData = ''
        res.on('data', function(chunk) { responseData += chunk })
        res.on('end', function() {
          if (res.statusCode === 200 && !('error' in JSON.parse(responseData))) {
            log('rm ' + path)
            fs.unlink(path)
          }
          else {
            err('error ' + res.statusCode)
            err(responseData)
          }
          if (i === torrents.length - 1) {
            var n = torrents.length - skipped.length
              , s = n === 1 ? '' : 's'
            if (n > 0) {
              notify(n + ' torrent' + s + ' → µTorrent')
            }
            writeLog()
          }
        })
      })
  log('torrent size: ' + torrentSize)
  log('total size: ' + data.length)
  req.end(data, 'binary')
})
