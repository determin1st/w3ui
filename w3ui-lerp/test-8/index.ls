"use strict"
document.addEventListener 'DOMContentLoaded', !->
    # initialize {{{
    # set default states
    freeIndex = 1
    # get nodes
    nodeMap =
        box: [...(document.querySelectorAll '.box')]
        container: [...(document.querySelectorAll '.container')]
    nodeMap <<<
        projectile1: nodeMap.box.0.querySelectorAll '.projectile' .0
        projectile2: [...(nodeMap.box.1.querySelectorAll '.projectile')]
    # create voice helper
    say = do ->
        # texts
        text =
            'Transforms ready'
            'You can Drag me'
            'Oh yeah, resize'
            'Yes'
        # initialize synth
        synth = window.speechSynthesis
        voice = null
        selectVoice = !->
            for a in synth.getVoices!
                if a.lang == 'en-US' and (a.name.indexOf 'Micros') == -1
                    voice := a
                    break
        # create function
        return (i) !->
            if not synth.speaking and b = text[i]
                # prepare
                text[i] = ''
                selectVoice! if not voice
                a = new SpeechSynthesisUtterance b
                # play
                a.voice = voice
                a.pitch = 1
                a.rate  = 1
                synth.speak a
    # }}}
    # create tweens {{{
    redsock.init!
    tween1 = redsock {
        target: nodeMap.projectile1
        className: '!tested'
        transform: 1
        duration: 0.8
        ease: 'power2-out'
        onComplete: !->
            if @tween.0.clas.last.includes 'tested'
                nodeMap.container.0.classList.add 'free'
                nodeMap.container.1.classList.remove 'free'
                freeIndex := 0
            else
                nodeMap.container.0.classList.remove 'free'
                nodeMap.container.1.classList.add 'free'
                freeIndex := 1
    }
    tween2 = redsock {
        target: nodeMap.projectile2
        className: '!tested'
        transform: 1
        duration: 0.6
        ease: 'power3-out'
    }
    # }}}
    # set events {{{
    # prepare containers of the first box
    nodeMap.container.forEach (node, index) !->
        # implement simplified drag/resize routine
        # {{{
        drag = 0
        size = 0
        x    = 0
        y    = 0
        prop = '--n'+(index + 1)+'-'
        cs   = window.getComputedStyle nodeMap.box.0
        pX   = parseFloat (cs.getPropertyValue prop+'x')
        pY   = parseFloat (cs.getPropertyValue prop+'y')
        sX   = parseFloat (cs.getPropertyValue prop+'w')
        sY   = parseFloat (cs.getPropertyValue prop+'h')
        cs   = nodeMap.box.0.style
        rect = [nodeMap.box.0.clientWidth, nodeMap.box.0.clientHeight]
        # }}}
        dragStart = (e) !-> # {{{
            # exclusive control
            e.preventDefault!
            e.stopPropagation!
            # check draggable
            if freeIndex == index and not drag
                # record click point
                x := e.clientX
                y := e.clientY
                # set state
                node.classList.add 'drag'
                if size
                    drag := 2
                    say 2
                else
                    drag := 1
        # }}}
        dragIt = (e) !-> # {{{
            if drag
                # exclusive control
                e.preventDefault!
                e.stopPropagation!
                # check mode
                if drag == 1
                    # determine new position
                    if (a = pX + e.clientX - x) < 0
                        a = 0
                    else if a > rect.0 - sX
                        a = rect.0 - sX
                    if (b = pY + e.clientY - y) < 0
                        b = 0
                    else if b > rect.1 - sY
                        b = rect.1 - sY
                    # update
                    pX := a
                    pY := b
                    cs.setProperty prop+'x', a+'px'
                    cs.setProperty prop+'y', b+'px'
                else
                    # determine new size
                    if size == 1
                        # width
                        if (a = sX + e.clientX - x) < 60
                            a = 60
                            dragStop!
                        else if a > rect.0 - pX
                            a = rect.0 - pX
                            dragStop!
                        # set
                        sX := a
                        cs.setProperty prop+'w', a+'px'
                    else
                        # height
                        if (b = sY + e.clientY - y) < 60
                            b = 60
                            dragStop!
                        else if b > rect.1 - pY
                            b = rect.1 - pY
                            dragStop!
                        # update
                        sY := b
                        cs.setProperty prop+'h', b+'px'
                # update initial point
                x := e.clientX
                y := e.clientY
        # }}}
        dragStop = (e) !-> # {{{
            if drag or size
                # exclusive control
                if e
                    e.preventDefault!
                    e.stopPropagation!
                # stop
                drag := 0
                size := 0
                node.classList.remove 'drag', 'resizeX', 'resizeY'
        # }}}
        hoverIt = (e) !-> # {{{
            if freeIndex == index and not drag
                # exclusive control
                e.preventDefault!
                e.stopPropagation!
                # determine offsets using hardcoded border value
                a = e.offsetX
                b = e.offsetY
                a = (a >= sX - 10 and a <= sX)
                b = (b >= sY - 10 and b <= sY)
                if a and not b
                    if size != 1
                        node.classList.add 'resizeX'
                        size := 1
                else if b and not a
                    if size != 2
                        node.classList.add 'resizeY'
                        size := 2
                else if size
                    node.classList.remove 'resizeX', 'resizeY'
                    size := 0
                else
                    say 1
        # }}}
        # set events
        # {{{
        node.addEventListener 'pointerdown', dragStart
        node.addEventListener 'pointermove', hoverIt
        nodeMap.box.0.addEventListener 'pointermove', dragIt
        node.addEventListener 'pointerup', dragStop
        nodeMap.box.0.addEventListener 'pointerleave', dragStop
        window.addEventListener 'resize', !->
            rect.0 = nodeMap.box.0.clientWidth
            rect.1 = nodeMap.box.0.clientHeight
            dragStop!
        # }}}
    ###
    # prepare projectiles
    nodeMap.projectile1.addEventListener 'pointerenter', !-> say 3
    nodeMap.projectile1.addEventListener 'click', !->
        if not tween1.active
            tween1.start!
    nodeMap.projectile2.forEach (node) !->
        node.addEventListener 'click', !->
            if not tween2.active
                tween2.start!
    # simulate resize
    setTimeout !->
        window.dispatchEvent (new Event 'resize')
        say 0
    , 1200
    # }}}
###
# vim: set et fdm=marker fenc=utf-8 ff=dos:
