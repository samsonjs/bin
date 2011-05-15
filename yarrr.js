#!/usr/bin/env node

require('batteries').extendNative()

var fs = require('fs')
  , http = require('http')
  , join = require('path').join
  , Downloads = join(process.env.HOME, 'Downloads')
  , created = JSON.parse(process.env.WATCH_CREATED)
  , torrents = created.grep(/.torrent$/i)
  , _log = []
  , log = function(s) { _log.push(s); console.log(s) }
  , writeLog = function() { fs.writeFileSync('/Users/sjs/bin/yarrr.log', _log.join('\n')) }

torrents.forEach(function(torrent, i) {
  log('>>> ' + torrent)
  var path = join(Downloads, torrent)
    , boundary = '48940923YARRRPIRATE3890457293'
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
            log('!!! error ' + res.statusCode)
            log('!!! ' + responseData)
          }
          if (i === torrents.length - 1) writeLog()
        })
      })
  log('torrent size: ' + torrentSize)
  log('total size: ' + data.length)
  req.end(data, 'binary')
})
