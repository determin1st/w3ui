"use strict"
do !->
    # define (manual setup)
    # hotspots
    hotspots = document.querySelectorAll '.hotspot'
    hotspots = [...hotspots] # convert to array
    activeHotspot = -1
    # hotspot cirles
    hotspotCirles = do ->
        res = []
        for spot in hotspots
            res.push (spot.querySelectorAll '.circle' .0)
        return res
    # hotspot copies
    hotspotCopies = do ->
        res = []
        for spot in hotspots
            res.push (spot.querySelectorAll '.copy' .0)
        return res
    # body
    body = document.querySelector 'body'
    # show animations
    showTl = do ->
        res = []
        for spot,index in hotspots
            a = new TimelineMax {
                paused: true
            }
            a.to hotspotCirles[index], 0.1, {
                autoAlpha: 0
            }
            a.to spot, 0.5, {
                width: 280
                borderRadius: 20
                backgroundColor: "hsla(0,0%,9%,.8)"
            }
            a.to hotspotCopies[index], 0.2, {
                autoAlpha: 1,
                ease: Power2.easeIn
            }
            res[index] = a
        return res
    # hide animations
    hideTl = do ->
        res = []
        for spot,index in hotspots
            a = new TimelineMax {
                paused: true
            }
            a.to hotspotCopies[index], 0.2, {
                autoAlpha: 0
                ease: Power2.easeIn
            }
            a.to spot, 0.5, {
                width: 120
                borderRadius: 100
                backgroundColor: "gray"
            }
            a.to hotspotCirles[index], 0.3, {
                autoAlpha: 1
                scaleX: 1
                scaleY: 1
            }
            res[index] = a
        return res
    # hover animations
    onTl = do ->
        res = []
        for spot,index in hotspots
            a = new TimelineMax {
                paused: true
            }
            a.to spot, 0.5, {
                backgroundColor:"pink"
            }
            a.to hotspotCirles[index], 0.5, {
                scaleX: 1.1
                scaleY: 1.1
            }, 0
            res[index] = a
        return res
    # unhover animations
    outTl = do ->
        res = []
        for spot,index in hotspots
            a = new TimelineMax {
                paused: true
            }
            a.to spot, 0.5, {
                backgroundColor:"gray"
            }
            a.to hotspotCirles[index], 0.5, {
                scaleX: 1
                scaleY: 1
            }, 0
            res[index] = a
        return res
    ##
    # event handlers and sync logic
    ##
    spotClick = (index) ->
        return (e) !->
            e.stopPropagation!
            if activeHotspot >= 0 and activeHotspot != index
                showTl[activeHotspot].kill!
                hideTl[activeHotspot].invalidate!play 0
            hideTl[index].kill!
            showTl[index].invalidate!play 0
            activeHotspot := index
    ##
    bodyClick = (e) !->
        e.stopPropagation!
        if activeHotspot >= 0
            showTl[activeHotspot].kill!
            hideTl[activeHotspot].invalidate!play 0
            activeHotspot := -1
    ##
    spotEnter = (index) ->
        return (e) !->
            if index != activeHotspot
                outTl[index].kill!
                onTl[index].invalidate!play 0
    ##
    spotLeave = (index) ->
        return (e) !->
            if index != activeHotspot
                onTl[index].kill!
                outTl[index].invalidate!play 0
    ##
    # initialize
    # bind event handlers
    body.addEventListener 'click', bodyClick
    for spot,index in hotspots
        spot.addEventListener 'click', (spotClick index)
        spot.addEventListener 'mouseenter', (spotEnter index)
        spot.addEventListener 'mouseleave', (spotLeave index)
    ##

