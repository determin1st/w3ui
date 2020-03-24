"use strict"
# animation engine timing tests
do !->
    # prepare
    # {{{
    queue = null
    state =
        engine: ''
        count: 0
        stagger: 0
        time: 4
        distance: 0
        started: 0
    nodeMap =
        engine: document.querySelectorAll '.ctl .engine' .0
        boxCount: document.querySelectorAll '.ctl .boxes' .0
        stagger: document.querySelectorAll '.ctl .stagger' .0
        box: document.querySelectorAll '.renderBox' .0
        projectile: []
        greensock: document.querySelectorAll '.ctl .opts .greensock' .0
        redsock: document.querySelectorAll '.ctl .opts .redsock' .0
        opts:
            greensock: [...(document.querySelectorAll '.ctl .opts .greensock .opt')]
            redsock: document.querySelectorAll '.ctl .opts .redsock .opt' .0
        bInit: document.querySelectorAll '.ctl .btn.n1' .0
        bRun: document.querySelectorAll '.ctl .btn.n2' .0
        bReset: document.querySelectorAll '.ctl .btn.n3' .0
    # }}}
    setup = !-> # {{{
        # check
        if state.started
            return
        # set options
        # engine
        # check
        a = nodeMap.engine.selectedIndex
        a = nodeMap.engine.options[a].value
        if a != state.engine
            # hide engine options
            if nodeMap.opts[state.engine]
                nodeMap[state.engine].classList.remove 'active'
            # update
            state.engine = a
            # show engine options
            if nodeMap.opts[a]
                nodeMap[a].classList.add 'active'
        # box count
        # check
        a = nodeMap.boxCount.selectedIndex
        a = parseInt nodeMap.boxCount.options[a].value
        if a != state.count
            # update
            state.count = a
            # re-create boxes
            nodeMap.box.innerHTML = ''
            nodeMap.projectile.length = 0
            for b from 1 to a
                c = document.createElement 'div'
                c.setAttribute 'class', 'projectile n'+(b - 1)
                nodeMap.box.appendChild c
                nodeMap.projectile.push c
            # reverse the order of elements
            nodeMap.projectile.reverse!
        # stagger
        # check
        a = nodeMap.stagger.selectedIndex
        a = parseFloat nodeMap.stagger.options[a].value
        if a != state.stagger
            # update
            state.stagger = a
        # set engine options
        if (o = nodeMap.opts[state.engine])
            switch state.engine
            | 'greensock' =>
                # get options
                a = o.1.selectedIndex
                a = parseInt o.1.options[a].value
                b = o.2.selectedIndex
                b = parseInt o.2.options[b].value
                # set lagSmoothing
                if o.0.checked
                    TweenLite.lagSmoothing a, b
                else
                    TweenLite.lagSmoothing 0
            | 'redsock' =>
                a = o.selectedIndex
                a = parseInt o.options[a].value
                redsock.minFPS = a
                redsock.cleanup!
        # reset
        nodeMap.bInit.classList.remove 'active'
        nodeMap.bInit.innerHTML = 'Construct'
        nodeMap.bRun.classList.remove 'active', 'ready'
        nodeMap.bRun.innerHTML = 'Run'
        nodeMap.bReset.classList.remove 'ready'
        nodeMap.box.classList.remove 'ready'
        nodeMap.projectile.map (node) ->
            node.style.transform = null
            node.style.top = null
        queue := null
        # done
    # }}}
    init = !-> # {{{
        # fix boxes
        nodeMap.projectile.map (node) ->
            node.style.transform = 'translateY(0px)'
            node.style.top = '0px'
        # calculate the distance
        a = nodeMap.box.clientWidth / (nodeMap.projectile.0.clientWidth + 2)
        a = 1 + ((state.count / a) .|. 0)
        a = a * (nodeMap.projectile.0.clientHeight + 2)
        state.distance = nodeMap.box.clientHeight - a
        # record current time
        time = window.performance.now!
        # initialize engine
        x = null
        /* INIT */
        switch state.engine
        | 'velocity' =>
            # +0
            # no construct!?
            # should reset animated properties explicitly
            x = nodeMap.projectile.map (node, index) ->
                $ node .velocity {
                    top:0
                }, {
                    duration:0
                }

        | 'jquery', 'transit' =>
            # +1
            # construct is simple but is way too simple
            # to be flexible
            x = nodeMap.projectile.map (node, index) -> $ node

        | 'popmotion' =>
            # +2
            # construct is way too obfuscated (not intuitive)
            x = nodeMap.projectile.map (node, index) ->
                # this gets some object to set style
                o = popmotion.styler node
                # this creates abstract tween
                # which is not bound to anything (may be bound to everything?)
                a = popmotion.tween {
                    from: 0
                    to: state.distance
                    duration: 1000 * state.time
                    ease: popmotion.easing.linear
                }
                # this updates style (previously it was onUpdate)
                return a.pipe (v) !->
                    # value must be specified with units
                    o.set {top: v+'px'}

        | 'greensock' =>
            # +3
            # construct is compact, but not factory
            # it describes animation type variants (tween/timeline and lite/max) and
            # node/duration/position/other options in its arguments.
            x = nodeMap.projectile.map (node, index) ->
                new TweenLite node, state.time, {
                    top: state.distance
                    overwrite: true
                    delay: (index + 1) * state.stagger
                    ease: Linear.easeNone
                    paused: true
                }

        | 'anime' =>
            # +4
            # construct is intuitive (factory)
            x = nodeMap.projectile.map (node, index) ->
                anime {
                    targets: node
                    top: state.distance
                    duration: 1000 * state.time
                    delay: 1000 * (index + 1) * state.stagger
                    easing: 'linear'
                    autoplay: false
                }

        | 'redsock' =>
            # +5
            # construct is intuitive (factory) and
            # flexible (allows to create nested animations)
            x = nodeMap.projectile.map (node, index) ->
                redsock {
                    queue:
                        {
                            duration: (index + 1) * state.stagger
                        }
                        {
                            duration: state.time
                            target: node
                            css:
                                top: state.distance
                        }
                }
        /**/
        # check the result
        if not x
            console.log 'failed to initialize "'+state.engine+'" engine'
            return
        # measure time
        time = (Math.abs (window.performance.now! - time)).toFixed 1
        a = (state.stagger * state.count + state.time).toFixed 1
        nodeMap.bRun.innerHTML = 'Run for '+a+' sec'
        nodeMap.bInit.classList.add 'active'
        nodeMap.bInit.innerHTML = 'Constructed in '+time+' ms'
        nodeMap.bRun.classList.add 'ready'
        nodeMap.box.classList.add 'ready'
        # done
        queue := x
    # }}}
    start = !-> # {{{
        # check
        if not queue or state.started
            return
        # set state
        nodeMap.bRun.classList.add 'active'
        nodeMap.bRun.innerHTML = 'Running...'
        state.started = window.performance.now!
        /* RUN */
        switch state.engine
        | 'popmotion' =>
            # initing chain()s and starting them with:
            /**
            queue.forEach (tween) !-> tween.start!
            /**/
            # fails to sync...
            # the code below, considered cheating for this test,
            # because animations should start individually and be controlled by the engine...
            # it's easier to sync animations with a single function..
            # but popmotion fails to do it even with this stagger:
            popmotion.stagger queue, state.stagger .start!

        | 'jquery' =>
            # jQuery is not flexible enough to detect delay == 0
            # and doesn't animate in sync if the delay(0) is called, so..
            # some check is required for this particular case
            if state.stagger
                queue.forEach (node, index) !->
                    a = 1000 * (index + 1) * state.stagger
                    node.delay a .animate {
                        top:state.distance
                    }, {
                        duration: 1000 * state.time
                        easing: 'linear'
                    }
            else
                queue.forEach (node, index) !->
                    node.animate {
                        top:state.distance
                    }, {
                        duration: 1000 * state.time
                        easing: 'linear'
                    }

        | 'velocity' =>
            # Velocity replicates jQuery's API, you only need to prepend it with velocity word..
            # It avoids jQuery bug, removing the need to check delay(0) case
            queue.forEach (node, index) !->
                node.velocity {
                    top: state.distance
                }, {
                    delay: 1000 * (index + 1) * state.stagger
                    duration: 1000*state.time
                    easing: 'linear'
                }

        | 'transit' =>
            # transit's API is more complicated than jQuery's
            # but implementation is more solid, which is shown in the visual test.
            # Maybe it was decided after realizing that second {Object}
            # parameter was often used to set duration and easing only..
            queue.forEach (node, index) !->
                node.transition {
                    top: state.distance
                    delay: 1000 * (index + 1) * state.stagger
                }, 1000*state.time, 'linear'

        | 'anime', 'greensock', 'redsock' =>
            # these are API friends..
            # simple method call because the engines allow to
            # initialize all options before startup
            queue.forEach (tween) !-> tween.play!
        /***/
        # set state
        nodeMap.bReset.classList.add 'ready'
        nodeMap.bReset.innerHTML = 'Lag'
        # set complete checker
        switch state.engine
        | 'greensock' =>
            # add callback to the last tween
            queue[queue.length - 1].eventCallback 'onComplete', finish
        | 'redsock' =>
            # add callback to the last tween
            queue[queue.length - 1].onComplete = finish
        | otherwise =>
            a = 1000 * state.stagger * state.count + 1000 * state.time + 1000
            window.setTimeout checkFinished, a
        # done
    # }}}
    checkFinished = !-> # {{{
        # check projectile
        a = state.count - 1
        a = parseInt nodeMap.projectile[a].style.top
        if a < state.distance
            # check later
            window.setTimeout checkFinished, state.time
            return
        # done
        finish!
    # }}}
    finish = !-> # {{{
        a = window.performance.now! - state.started
        a = (a / 1000).toFixed 2
        nodeMap.bRun.innerHTML = 'Finished in '+a+' sec'
        nodeMap.bReset.innerHTML = 'Reset'
        state.started = 0
        queue := null
    # }}}
    reset = !-> # {{{
        # check
        if queue
            # inject lag
            a = window.performance.now!
            while (window.performance.now! - a) < 1000 * state.time / 2
                true
        else
            # reset state
            state.started = 0
            setup!
        # done
    # }}}
    # set events
    nodeMap.engine.addEventListener 'change', setup
    nodeMap.boxCount.addEventListener 'change', setup
    nodeMap.stagger.addEventListener 'change', setup
    nodeMap.opts.greensock.0.addEventListener 'change', setup
    nodeMap.opts.greensock.1.addEventListener 'change', setup
    nodeMap.opts.greensock.2.addEventListener 'change', setup
    nodeMap.opts.redsock.addEventListener 'change', setup
    window.addEventListener 'resize', setup
    nodeMap.bInit.addEventListener 'click', init
    nodeMap.bRun.addEventListener 'click', start
    nodeMap.bReset.addEventListener 'click', reset
    # initialize
    setup!

# vim: set et ts=4 sw=4 sts=4 fdm=marker fenc=utf-8 ff=dos:
