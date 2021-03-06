fs = require 'fs'
PaVEParser = require './PaVEParser'
keypress = require 'keypress'

module.exports = droner =
  augment: (client) ->
    client._tcpVideoStream = client.createPngStream()._tcpVideoStream
    client._rawVideoStream = client._tcpVideoStream.pipe new PaVEParser

    client.config 'general:navdata_demo', 'TRUE'

    client.battery = -> client._lastBattery

    client.safeguard = ->
      client.disableEmergency()
      return client

    client.record = (loc) ->
      client._rawVideoStream.pipe fs.createWriteStream loc, flags: 'a'
      return client

    client.enableControls = (speed=0.5, dur=250) ->
      flying = false
      controls =
        right: ({shift}) ->
          client.counterClockwise speed
          unless shift
            client.after dur, -> client.counterClockwise 0
        left: ({shift}) ->
          client.clockwise speed
          unless shift
            client.after dur, -> client.clockwise 0
        up: ({shift}) ->
          client.up speed
          unless shift
            client.after dur, -> client.up 0
        down: ({shift}) ->
          client.down speed
          unless shift
            client.after dur, -> client.down 0
        w: ({shift}) ->
          client.front speed
          unless shift
            client.after dur, -> client.front 0
        a: ({shift}) ->
          client.left speed
          unless shift
            client.after dur, -> client.left 0
        s: ({shift}) ->
          client.back speed
          unless shift
            client.after dur, -> client.back 0
        d: ({shift}) ->
          client.right speed
          unless shift
            client.after dur, -> client.right 0
        space: ->
          if flying
            client.land()
          else
            client.takeoff()
          flying = !flying
        x: -> client.stop()
        r: -> client.disableEmergency()
        "1": -> client.animate "flipAhead", 15
        "2": -> client.animate "flipLeft", 15
        z: ->
          client.takeoff()
          client.once 'hovering', ->
            client.clockwise speed
            #client.up speed
            client.after 3000, ->
              client.clockwise 0
              #client.up 0
              #client.down speed
              client.counterClockwise speed
              client.after 2000, ->
                client.counterClockwise 0
                #client.down 0
                client.land()



      keypress process.stdin
      process.stdin.on 'keypress', (_, k) ->
        return unless k
        return process.exit() if k.ctrl and k.name is 'c'
        controls[k.name]? k

      process.stdin.setRawMode true
      process.stdin.resume()

      console.log """

        Controls:
        w - forward
        a - left
        s - backward
        d - right

        arrow up - up
        arrow left - spin left
        arrow down - down
        arrow right - spin right

        <space> - land/takeoff
        x - hover
        r - disable emergency mode
        1/2 - flipAhead/flipLeft

      """

      return client

    return client