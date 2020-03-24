"use strict"
/* web 3.0 user interface */
w3ui = do ->
    DEP = # dependencies {{{
        [Object.entries, "ECMAScript® 2018"]
        [window.requestAnimationFrame, "WHATWG HTML Living Standard"]
        [document.body.offsetLeft != undefined, "CSSOM View Module 2016"]
        [!!redsock, "redsock animation library"]
    # check it
    # use back-compat syntax and dont flood vars
    DEP = do ->
        # check each and report problem
        b = true
        for a in DEP when not a.0
            b = false
            console.log "w3ui requires "+a.1
        # to be
        return b
    # or not to be?
    return null if not DEP
    # }}}
    CLONE = (obj, trace = []) -> # deep clone of the data object {{{
        switch typeof! obj
        | 'Date'   => return new Date obj.getTime!
        | 'RegExp' => return new RegExp obj
        | 'Object' =>
            # check object prototype
            # lets clone only simple objects
            if Object.prototype != Object.getPrototypeOf obj
                return obj
            # check trace to avoid repeats
            for [a, b] in trace when obj == a
                return b
            # create clone
            c = {}
            for own a,b of obj
                c[a] = CLONE b, trace
            # update trace
            trace.push [obj, c]
            # done
            obj = c
        | 'Array' =>
            # check trace to avoid repeats
            for [a, b] in trace when obj == a
                return b
            # clone array
            c = obj.map (a) -> CLONE a, trace
            for own a,b of obj
                c[a] = CLONE b, trace
            # update trace
            trace.push [obj, c]
            # done
            obj = c
        | otherwise =>
            # "as is"
        # done
        obj
    # }}}
    PROXY = do -> # abstracted proxy object {{{
        # prepare abstract proxy
        prx =
            set: (obj, key, val, prx) -> # {{{
                # check
                if typeof key != 'string'
                    return true
                # intercept special keys
                if key.0 == '$'
                    # change scope (rebind)
                    if key == '$scope'
                        prx = obj.$handler
                        obj.$set = prx.set.bind val if prx.set
                        obj.$get = prx.get.bind val if prx.get
                    # store
                    obj[key] = val
                    return true
                # call bound setter
                return obj.$set obj.$data, key, val, prx
            # }}}
            get: (obj, key, prx) -> # {{{
                # check
                if typeof key != 'string'
                    return false
                # intercept special keys
                return obj[key] if key.0 == '$'
                # call bound getter
                return obj.$get obj.$data, key, prx
            # }}}
        # prepare default methods
        setDefault = (obj, key, val) -> # {{{
            obj.$data[key] = val
            return true
        # }}}
        getDefault = (obj, key) -> # {{{
            return obj.$data[key]
        # }}}
        # define constructor
        return (obj, handler, scope = obj) ->
            # initialize wrapper object
            a = if handler.init
                then handler.init obj
                else obj
            a =
                $data: a
                $handler: handler
                $scope: scope
                $clone: (obj) -> PROXY obj, handler
                $set: if handler.set
                    then handler.set.bind scope
                    else setDefault
                $get: if handler.get
                    then handler.get.bind scope
                    else getDefault
            # create proxy
            return new Proxy a, prx
    # }}}
    THREAD = (chain) !-> # run functions chain {{{
        # prepare
        index = 0
        func  = !->
            # delay
            window.requestAnimationFrame !->
                # call function and check the result
                switch chain[index]!
                # repeat
                | false => func!
                # next
                | true, undefined => func! if chain[++index]
                # end
                return
        # start
        func!
    # }}}
    STATE = do -> # state change helper {{{
        # prepare
        # define checkers
        checker = {
            boolean: (data, key, val) -> data[key] != val
            string: (data, key, val) -> data[key] != val
            number: (data, key, val) ->
                if key of data
                    if (Math.abs data[key] - val) < 0.000001
                        return false
                return true
        }
        # define handler
        handler = {
            set: (store, key, val) ->
                # check
                if checker[typeof val] store.data, key, val
                    # backup current value
                    store['$' + key] = store.data[key]
                    # set dirty flag
                    store.dirty[key] = true
                    # change
                    store.data[key] = val
                # done
                return true
            get: (store, key) ->
                # check old value request
                if key.0 == '$'
                    # return previous
                    if (key of store)
                        return store[key]
                    # return current
                    return store.data[key.slice 1]
                # check dirty
                if not store.dirty[key]
                    return false
                # clear
                store.dirty[key] = false
                return true
        }
        # construct
        return (data) ->
            return new Proxy {data: data, dirty: {}}, handler
    # }}}
    GSAP = # {{{
        queue: (data, node) -> # {{{
            # create timeline
            a = new TimelineLite {paused:true}
            # check
            if data
                # convert to array
                data = [data] if not Array.isArray data
                # add tweens
                @add a, node, data
            # done
            return a
        # }}}
        add: (timeline, node, source, position = '+=0') !-> # {{{
            # check
            return if not source
            # iterate
            for a in source
                switch typeof a
                # tween
                | 'object' =>
                    # check
                    break if a.disabled
                    # prepare
                    node = a.node if 'node' of a
                    pos = if 'position' of a
                        then a.position
                        else position
                    # check nodes
                    if not node or ('length' of node and not node.length)
                        break
                    if 'w3ui' of node
                        node = node.nodes
                    # check type
                    # label
                    if a.label
                        timeline.addLabel a.label, pos
                        pos = a.label
                    # another group (queue)
                    if a.group
                        # get group
                        b = if a.func
                            then a.func!
                            else a.group
                        # check
                        break if not b
                        # recurse
                        b = @queue b, node
                        if 'duration' of a
                            b.duration = a.duration
                        timeline.add b.play!, pos
                        break
                    # callback
                    if 'func' of a and a.func
                        b = if a.scope
                            then a.func.bind a.scope
                            else a.func
                        timeline.add b, pos
                        break
                    # animation tween
                    break if not a.to and not a.from
                    # prepare
                    b =
                        if a.to
                            then w3ui.CLONE a.to
                            else null
                        if a.from
                            then w3ui.CLONE a.from
                            else null
                    # set
                    if not a.duration or a.duration < 0.0001
                        timeline.set node, (b.0 or b.1), pos
                        break
                    # animate to
                    if b.0 and not b.1
                        timeline.to node, a.duration, b.0, pos
                        break
                    # animate from
                    if not b.0 and b.1
                        timeline.from node, a.duration, b.1, pos
                        break
                    # animate fromTo
                    timeline.fromTo node, a.duration, b.0, b.1, pos
                # callback
                | 'function' =>
                    # GSAP pause
                    if a.length
                        b = new Proxy timeline, apiHandler
                        timeline.addPause '+=0', a, [b]
                        break
                    # callback
                    timeline.add a
                # add label
                | 'string' =>
                    timeline.addLabel a
        # }}}
        joinTimelines: (list, queue = false) !-> # {{{
            # check empty
            if not list or not list.length
                return null
            # check single
            if list.length < 2
                return list.0
            # join
            # use first timeline
            a = list.0
            for b from 1 to list.length - 1
                if queue
                    then a.add list[b].play!
                    else a.add list[b].play!, 0
            # done
            return a
        # }}}
        pauseAll: (timeline) !-> # {{{
            do
                timeline.pause!
            while (timeline = timeline.timeline)
        # }}}
        resumeAll: (timeline) !-> # {{{
            do
                timeline.resume! if not timeline.isActive!
            while (timeline = timeline.timeline)
        # }}}
        removeAtLabel: (timeline, label) !-> # {{{
            # get label
            if (a = timeline.getLabelTime label) == -1
                return
            # get children
            b = timeline.getChildren false, true, true, a
            # iterate and remove
            for c in b when c.startTime! == a
                console.log 'found a tween to remove at [' + label + ']'
                timeline.remove c
        # }}}
    # }}}
    WIDGET = # {{{
        store: {}
        construct: (name) -> (selector, opts) -> # {{{
            # check
            if not (name of WIDGET.store)
                console.log 'w3ui: widget «'+name+'» is not loaded'
                return null
            # query node
            if not (node = QUERY selector)
                console.log 'w3ui: DOM query failed for «'+selector+'»'
                return null
            # apply w3ui classes
            node.class.add ['w3ui', 'widget', name]
            # create and initialize new widget
            widget = WIDGET.store[name]
            widget = ^^widget <<< {
                name: name
                node: node
                data: CLONE widget.data
                ...WIDGET.base
            }
            # create
            if not widget.create opts
                widget.log 'failed to create'
                return null
            # done
            return widget.api
        # }}}
        base:
            # interfaces
            options: do -> # configuration {{{
                # define
                base =
                    theme: 'DEFAULT'    # interface style theme
                    orientation: false  # 0=Default axis X/Y, 1=Reversed Y/X
                    responsive: false   # call resize on window resize (no APP, autonomy)
                    animate: true       # show transition effects
                    log: true           # display logs in console
                    disabled: false     # no event processing
                # construct
                return !->
                    # combine base and default widget options
                    @options = ^^base <<< (CLONE @__proto__.options)
            # }}}
            attach: do -> # events {{{
                attach = !-> # {{{
                    # initialize events data
                    if not @attach.ready
                        for a in @data.events
                            # determine target nodes
                            a.node = if not a.el
                                then @node
                                else if typeof a.el == 'string'
                                    then QUERY a.el, @node
                                    else [a.el]
                            # set handlers
                            a.handler = a.node.map (el, index) ~>
                                b = ^^a <<< {
                                    el
                                    index
                                }
                                return react.bind @, b
                        # done
                        @attach.ready = true
                    # attach
                    for a in @data.events
                        for b,c in a.node
                            b.addEventListener a.event, a.handler[c]
                    # set detacher
                    @detach = detach.bind @
                # }}}
                react = (data, event) !-> # {{{
                    # call handler
                    if @__proto__.react.call @, data, event
                        # event successfully handled
                        # prevent default action
                        event.preventDefault!
                    # done
                    return true
                # }}}
                detach = !-> # {{{
                    for a in @data.events
                        for b,c in a.node
                            b.removeEventListener a.event, a.handler[c]
                # }}}
                return !->
                    @attach = attach.bind @
            # }}}
            api: do -> # external {{{
                # prepare
                options = # {{{
                    set: (obj, key, val) ->
                        # check
                        if not (key of obj)
                            @log 'unknown option «'+key+'»'
                            return true
                        # set
                        if (val = @setup key, val) != undefined
                            obj[key] = val
                        # done
                        return true
                    get: (obj, key) ->
                        if not (key of obj)
                            return null
                        return CLONE obj[key]
                # }}}
                # construct
                return !->
                    # specific
                    api = {}
                    for a,b of @__proto__.api
                        api[a] = if typeof b == 'function'
                            then b.bind @
                            else b
                    # common
                    api <<< {
                        w3ui: @
                        name: @name
                        node: @node
                        animation: @animation.bind @
                        attach: @attach
                        detach: !~> @detach! if @detach
                        destroy: @destroy.bind @
                        resize: @resize.bind @
                    }
                    Object.defineProperty api, 'options', {
                        get: let a = PROXY @options, options, @
                            return -> a
                        set: (opts) !~>
                            # check
                            if typeof! opts != 'Object'
                                return
                            # determine iteration order
                            a = Object.keys opts
                            b = if @options.ORDER
                                then @options.ORDER.slice!
                                else []
                            # get keys
                            for c in a when not b.includes c
                                b.push c
                            # iterate and set
                            for a in b
                                # using public api
                                @api.options[a] = opts[a]
                    }
                    @api = api
            # }}}
            # methods
            create: (options) -> # {{{
                # initialize interfaces
                @options!
                @attach!
                @api!
                # initialize sub-objects
                if 'INIT' of @data
                    @data.INIT.forEach (a) !~> @[a]!
                # set options
                @api.options = options
                # set theme
                @node.class.add @options.theme
                # call widget's create
                if (a = @__proto__.create) and not a.call @
                    return false
                # set global resize handler
                if @options.responsive
                    window.addEventListener 'resize', @api.resize
                # done
                return true
            # }}}
            destroy: !-> # {{{
                # clear DOM classes
                @node.class.remove ['w3ui', @name]
                # detach events
                @detach! if @detach
                # detach window resize handler
                if @options.responsive
                    window.removeEventListener 'resize', @api.resize
                # destroy sub-objects
                if 'INIT' of @data
                    @data.INIT.forEach (a) !~> @[a].destroy!
                # call custom destroy procedure
                (a = @__proto__.destroy) and a.call @
            # }}}
            resize: !-> # {{{
                (a = @__proto__.resize) and a.call @
            # }}}
            setup: (key, val) -> # options {{{
                # check
                if not (a = @__proto__.setup)
                    return val
                # handle base options
                switch key
                | 'responsive' =>
                    # prevent option change,
                    # the change is possible only upon creation
                    return @options[key]
                # handle widget option
                return a.call @, key, val
            # }}}
            log: (msg) !-> # {{{
                console.log 'w3ui.'+@name+': '+msg if @options.log
            # }}}
    # }}}
    QUERY = do -> # DOM node wrapper {{{
        api = # {{{
            w3ui: # {{{
                _property: true
                get: -> @
            # }}}
            query: # {{{
                _func: (selector, noWrap = false) ->
                    # prepare
                    if @selector
                        selector = @selector+' '+selector
                    # query
                    QUERY selector, @node, noWrap
            # }}}
            node: # {{{
                _property: true
                get: -> @node
            # }}}
            nodes: # {{{
                _property: true
                get: -> @nodes
            # }}}
            clone: # {{{
                _func: (deep = true) ->
                    @node.cloneNode deep
            # }}}
            html: # {{{
                _property: true
                get: -> @node.innerHTML
                set: (val) !-> @node.innerHTML = val
            # }}}
            style: # {{{
                _proxy: true
                get: (data, key) -> # {{{
                    # get computed style
                    s = if data.group
                        then data.style.0
                        else data.style
                    # get property
                    a = s[key]
                    # get CSS variable
                    if a == undefined
                        a = key.replace //([A-Z])//g, (a) ->
                            '-' + a.0.toLowerCase!
                        a = s.getPropertyValue '--'+a
                    # check the result
                    if typeof a == 'string'
                        # trim
                        a = a.trim!
                        # convert pixels
                        if a.length > 2 and (a.substr -2) == 'px'
                            a = parseFloat a
                            a = 0 if isNaN a
                        # zerocheck
                        else if a == '0'
                            a = 0
                    # done
                    return a
                # }}}
                set: (data, key, val) -> # {{{
                    # get computed style
                    s = if data.group
                        then data.style.0
                        else data.style
                    # check
                    if s[key] == undefined
                        # set CSS variable
                        a = key.replace //([A-Z])//g, (a) ->
                            '-' + a.0.toLowerCase!
                        data.node.style.setProperty '--'+a, val
                    else
                        # set inline property
                        data.node.style[key] = val
                    # done
                    true
                # }}}
            # }}}
            box: # {{{
                state: -> # {{{
                    # iterate box properties
                    x = {}
                    a = @api.box
                    for b,c of api.box when not c.length and b != 'state'
                        x[b] = a[b]
                    # done
                    return x
                # }}}
                innerWidth: -> # {{{
                    a = @api.style
                    return @node.clientWidth - (a.paddingLeft + a.paddingRight)
                # }}}
                innerHeight: -> # {{{
                    a = @api.style
                    return @node.clientHeight - (a.paddingTop + a.paddingBottom)
                # }}}
                width: -> # {{{
                    @node.clientWidth
                # }}}
                height: -> # {{{
                    @node.clientHeight
                # }}}
                outterWidth: -> # {{{
                    a = @api.style
                    return @node.clientWidth +
                        (a.borderLeftWidth + a.borderRightWidth) +
                        (a.marginLeft + a.marginRight)
                # }}}
                outterHeight: -> # {{{
                    a = @api.style
                    return @node.clientHeight +
                        (a.borderTopWidth + a.borderBottomWidth) +
                        (a.marginTop + a.marginBottom)
                # }}}
                paddingWidth: -> # {{{
                    a = @api.style
                    return a.paddingLeft + a.paddingRight
                # }}}
                paddingHeight: -> # {{{
                    a = @api.style
                    return a.paddingTop + a.paddingBottom
                # }}}
                borderWidth: -> # {{{
                    a = @api.style
                    return a.borderLeftWidth + a.borderRightWidth
                # }}}
                borderHeight: -> # {{{
                    a = @api.style
                    return a.borderTopWidth + a.borderBottomWidth
                # }}}
                textMetrics: (text, fontSize = 0) -> # {{{
                    # prepare
                    a = @api.style
                    b = DEP.context2d
                    c = if fontSize
                        then fontSize
                        else a.fontSize
                    # define font parameters
                    c =
                        a.fontStyle
                        a.fontWeight
                        c + 'px'
                        a.fontFamily
                    # apply to common context
                    b.font = c.join ' '
                    # get metrics
                    return b.measureText text
                # }}}
                fontSize: (text) -> # {{{
                    # check
                    if not text or not typeof text == 'string'
                        return 0
                    # prepare
                    api = @api.box
                    a = api.innerHeight # maximal size
                    b = api.innerWidth
                    c = [0, a]
                    # binary search
                    # determine apropriate font size
                    while c.1 - c.0 > 0.5
                        # measure
                        if not d = api.textMetrics text, a
                            return 0
                        # check
                        if d.width <= b
                            # enlarge
                            c.0 = a
                        else
                            # reduce
                            c.1 = a
                        # take next value
                        a = c.0 + (c.1 - c.0) / 2.0
                    # done
                    c.0
                # }}}
            # }}}
            class: # {{{
                _property: true
                _proxy: true
                set: (val) !-> # {{{
                    @node.className = val if typeof val == 'string'
                # }}}
                has: (name) -> # {{{
                    @node.classList.contains name
                # }}}
                ###
                add: (name) !-> # {{{
                    # single
                    if typeof name == 'string'
                        @node.classList.add name
                        return
                    # multiple
                    name.forEach and name.forEach (a) !~>
                        @node.classList.add a
                # }}}
                remove: (name) !-> # {{{
                    if not name
                        # remove all
                        @api.class.clear!
                    else if typeof name == 'string'
                        # remove one
                        @node.classList.remove name
                    else
                        # remove multiple
                        name.forEach and name.forEach (name) !~>
                            @node.classList.remove name
                # }}}
                clear: (except = '') !-> # {{{
                    # prepare
                    a = @node.classList
                    b = a.length
                    if not except
                        # remove all
                        while --b >= 0
                            a.remove a.item b
                    else
                        # remove some
                        except += ' '
                        while --b >= 0
                            c = a.item b
                            a.remove c if not except.includes c+' '
                # }}}
                replace: (name0, name1) -> # {{{
                    @node.classList.replace name0, name1
                # }}}
                toggle: (name, flag) -> # {{{
                    # check flag
                    if typeof flag == 'function'
                        flag = flag @wrap, @index
                    # toggle
                    @node.classList.toggle name, !!flag
                # }}}
            # }}}
            classAdd: # {{{
                _group: true
                _func: (name) !->
                    @group.forEach (node) !-> node.class.add name
            # }}}
            classRemove: # {{{
                _group: true
                _func: (name) !->
                    @group.forEach (node) !-> node.class.remove name
            # }}}
            classToggle: # {{{
                _group: true
                _func: (name, flag) !->
                    @group.forEach (node) !->
                        node.class.toggle name, flag
            # }}}
            prop: # {{{
                _proxy: true
                get: (data, key) -> # {{{
                    # prepare key
                    key = key.replace //([A-Z])//g, (a) ->
                          '-' + a.0.toLowerCase!
                    # get
                    return data.node.getAttribute key
                # }}}
                set: (data, key, val) -> # {{{
                    # prepare key
                    key = key.replace //([A-Z])//g, (a) ->
                          '-' + a.0.toLowerCase!
                    # remove
                    if val == null
                        data.node.removeAttribute key
                        return true
                    # set
                    data.node.setAttribute key, val
                    return true
                # }}}
                has: (data, key) -> # {{{
                    data.node.hasAttribute key
                # }}}
            # }}}
            props: # {{{
                _proxy: true
                _group: true
                get: (data, key) -> # {{{
                    data.group.map (node) -> node.prop[key]
                # }}}
                set: (data, key, val) -> # {{{
                    data.group.forEach (node) !->
                        node.prop[key] = val
                    return true
                # }}}
                has: (data, key) -> # {{{
                    data.nodes.some (node) ->
                        node.hasAttribute name
                # }}}
            # }}}
            child: # {{{
                add: (node, parent = @node) !-> # {{{
                    if 'w3ui' of node
                        # recurse and append w3ui node(s)
                        api.child.add node.nodes, parent
                    else if typeof! node == 'Array'
                        # append nodes
                        node.forEach (node) !->
                            parent.appendChild node
                    else
                        # append single node
                        parent.appendChild node
                # }}}
                insert: (node, index = 0, parent = @node) !-> # {{{
                    # check if parent is empty
                    if parent.children.length == 0
                        # no need to insert
                        api.child.add node, parent
                        return
                    # get index
                    if index < 0
                        index = 0
                    else if index > (a = parent.children.length - 1)
                        index = a
                    # get child
                    a = parent.children[index]
                    # insert
                    # w3ui node
                    if 'w3ui' of node
                        # get node
                        node = if node.w3ui.group
                            then node.nodes
                            else node.node
                        # static recurse
                        api.child.insert node, index, parent
                        return
                    # regular node
                    if typeof! node == 'Array'
                        # multiple
                        node.forEach (node) !->
                            parent.insertBefore node, a
                    else
                        # single
                        parent.insertBefore node, a
                # }}}
                remove: (node = null, parent = @node) -> # {{{
                    # remove all
                    if not node
                        a = document.createRange!
                        a.selectNodeContents parent
                        a.deleteContents!
                        return
                    # remove specific
                    # w3ui node
                    if 'w3ui' of node
                        # get it
                        node = if node.w3ui.group
                            then node.nodes
                            else node.node
                        # static recurse
                        api.child.remove node, parent
                        return
                    # regular node
                    if typeof! node == 'Array'
                        node.forEach (node) !->
                            parent.removeChild node
                    else
                        parent.removeChild node
                # }}}
            # }}}
            ##
            addEventListener: # {{{
                _property: true
                get: -> @node.addEventListener.bind @node
            # }}}
            removeEventListener: # {{{
                _property: true
                get: -> @node.removeEventListener.bind @node
            # }}}
        # }}}
        apiProxy = # {{{
            get: ([data, api], key) ->
                # check key
                if not (isNaN parseInt key) or not (api = api[key])
                    return null
                # check api type (method/property)
                return if api.length > 0
                    then api.bind data
                    else api.call data
            set: ([data, api], key, val) ->
                api.set.call data, key, val if 'set' of api
                return true
        # }}}
        apiBind = (data, target = {}) -> # {{{
            # iterate each api and bind it
            for b,a of api
                # check group-only
                if a._group and not data.group
                    continue
                # determine api type
                if a._func
                    # method
                    a = {value: a._func.bind data}
                else if a._property
                    # property (or proxied property)
                    # getter
                    c = {}
                    if a._proxy
                        c.get = let a = (new Proxy [data, a], apiProxy)
                            return -> a
                    else if 'get' of a
                        c.get = a.get.bind data
                    # setter
                    c.set = a.set.bind data if a.set
                    a = c
                else if a._proxy
                    # simple proxy
                    a = {value: new Proxy data, a}
                else
                    # proxied methods and properties
                    a = {value: new Proxy [data, a], apiProxy}
                # bind
                Object.defineProperty target, b, a
            # done
            return target
        # }}}
        wrapNode = (node, boundApi) -> # {{{
            return new Proxy node, {
                get: (node, key) ->
                    return if key of api
                        then boundApi[key]
                        else Reflect.get node, key
                set: (node, key, val) ->
                    if key of api
                        boundApi[key] = val
                        return true
                    return Reflect.set node, key, val
                has: (node, key) ->
                    return if key of api
                        then true
                        else Reflect.has node, key
            }
        # }}}
        getNodes = (selector, parent) -> # {{{
            # check type
            node = []
            switch typeof! selector
            | 'String' =>
                # check
                # multiple parents
                if 'w3ui' of parent
                    # recurse
                    for a in parent.w3ui.nodes
                        node = node ++ getNodes selector, a
                    # done
                    break
                # single parent
                # query DOM elements
                if selector
                    if not (a = parent.querySelectorAll selector).length
                        if parent.matches selector
                            node.push parent
                            break
                else
                    a = parent.children
                # convert NodeList to array
                a = Array.from a
            | 'Array' =>
                # recurse
                for a in selector when a
                    node = node ++ getNodes a, parent
            | otherwise =>
                # check selector
                if 'w3ui' of selector
                    return selector.nodes
                # add as is
                node.push selector
            # done
            return node
        # }}}
        return (selector, parent = document, noWrap = false) ->
            # get nodes
            node = getNodes selector, parent
            if not node.length
                return null
            # check
            return node if noWrap
            # compute styles
            style = node.map (el) ->
                window.getComputedStyle el
            # create main data object
            data =
                group: true             # main wrapper (self)
                selector: selector      # css
                nodes: node             # DOM elements
                node: node.0            # first DOM element
                index: 0                # element index
                parent: parent          # DOM parent
                style: style            # computed styles
            # wrap each node
            node = node.map (el, index) ->
                # clone data and use function scope to store it
                a = Object.create data
                # create wrapper and store
                a <<< {
                    group: null
                    nodes: [el]
                    node: el
                    index: index
                    style: style[index]
                    api: apiBind a
                    wrap: wrapNode el, a.api
                }
                return a
            # initialize
            # add shortcuts for the first node
            data.api  = node.0.api
            data.wrap = node.0.wrap
            # create main wrapper
            data.group = apiBind data, (node.map (el) -> el.wrap)
            # done
            return data.group
    # }}}
    APP = do -> # w3ui MVP application {{{
        ###
        MODEL = # {{{
            data: # {{{
                nav: [
                    {id: ''}
                    {id: ''}
                    {id: ''}
                    {id: ''}
                    {id: ''}
                ]
                navHistory: [{} {} {} {}]
                navDefault: null
                navPath: ->
                    return @nav.map (a) -> a.id
            # }}}
            proxy: # {{{
                init: (obj) -> # {{{
                    # initialize navigation store
                    a = obj.nav
                    obj.navHistory.forEach (save, level) !->
                        save[''] = w3ui.CLONE a.slice level + 1
                    # set current path
                    obj.navDefault and obj.navDefault.forEach (id, level) !->
                        obj.nav[level].id = id
                    # done
                    obj
                # }}}
                set: (obj, k, v, prx) -> # {{{
                    # set data
                    a = parseInt k
                    if isNaN a
                        obj[k] = v
                        return true
                    # set navigation
                    # prepare
                    k   = a
                    nav = obj.nav
                    a   = nav[k]
                    sav = if k < obj.navHistory.length
                        then obj.navHistory[k]
                        else null
                    # no change
                    return true if a.id == v == ''
                    # reset
                    v = '' if a.id == v
                    # backup/restore
                    if sav
                        # backup
                        k++
                        sav[a.id] = w3ui.CLONE nav.slice k
                        # clear higher levels
                        for b from k to nav.length - 1
                            w3ui.clearObject nav[b]
                        #nav.splice k + 1
                        # get previous data
                        sav = if sav[v]
                            then sav[v]
                            else sav['']
                        # restore
                        for b,c in sav
                            nav[k + c] <<< sav[c]
                    # change
                    a.id = v
                    true
                # }}}
                get: (obj, p, prx) -> # {{{
                    # get navigation object
                    k = parseInt p
                    return obj.nav[k].id if not isNaN k
                    # check existance
                    return null if not (p of obj)
                    # get it
                    k = obj[p]
                    # check for simple self-named getter
                    if typeof k == 'function' and k.length == 0
                        return k!
                    # return as is
                    return obj[p]
                # }}}
            # }}}
        # }}}
        VIEW = # {{{
            init: do -> # {{{
                M = null
                V = null
                P = null
                initNode = (id, node, parent, level, tid) -> # {{{
                    # prepare
                    cfg = node.cfg
                    tid = tid + '-' + id if level > 0
                    # initialize
                    cfg.id       = id
                    cfg.parent   = parent
                    cfg.level    = level
                    cfg.nav      = M.nav[level]
                    cfg.render   = V.render.bind node, cfg.render if cfg.render != undefined
                    cfg.attach   = V.attach.bind node, P, cfg.attach if cfg.attach
                    cfg.template = V.template.querySelector tid
                    cfg.data     = {}
                    cfg.el       = V.el
                    # initialize animations
                    cfg.show and initAnimation node, cfg.show
                    cfg.hide and initAnimation node, cfg.hide
                    if cfg.turn
                        if cfg.turn.on
                            initAnimation node, cfg.turn.off
                            initAnimation node, cfg.turn.on
                        else
                            initAnimation node, cfg.turn
                    # recurse to children
                    for own a,b of node when a != 'cfg' and b and b.cfg
                        @init a, b, node, level + 1, tid
                    # complete
                    true
                # }}}
                initAnimation = (node, queue) !-> # {{{
                    # bind tween functions
                    for a,b in queue
                        # check type
                        if typeof a == 'function'
                            queue[b] = a.bind node
                            continue
                        # check object type
                        if a.func
                            queue[b].func = a.func.bind node
                            continue
                        # recurse
                        if a.group
                            initAnimation node, a.group
                # }}}
                return ->
                    # prepare
                    [M, V, P] := arguments
                    # initialize
                    V.template = document.querySelector 'template' .content
                    V.init = initNode.bind V
                    V.el   = V.el M, V
                    V.call = V.call M
                    # initialize interface nodes
                    if not V.init 'ui', V.ui, null, 0, '#t'
                        console.log 'w3ui.app: failed to initialize view'
                        return false
                    # done
                    true
            # }}}
            render: (template, old = '') -> # {{{
                # prepare
                # get identifier from model
                id = @cfg.nav.id
                # update DOM node link
                if not @cfg.node
                    @cfg.node = w3ui '#'+@cfg.id
                # determine node type
                a = @cfg.parent
                b = if not a or a.cfg.nav.id == @cfg.id
                    then id
                    else ''
                # update adjacent node context
                if not b and id and (c = a[a.cfg.nav.id][id])
                    @cfg.context = c
                # check if render required
                return true  if not template or not id
                return false if not @cfg.node
                # get template data
                if b
                    # for primary
                    a = @[id].cfg.template.innerHTML
                    c = @[id]
                else
                    # for adjacent
                    a = if (a = @cfg.template.querySelector '#'+id)
                        then a.innerHTML
                        else ''
                    c = if @[id]
                        then @[id].render.call @
                        else null
                # render
                if not (a = Mustache.render a, c)
                    return true
                # create DOM template
                d = document.createElement 'template'
                d.innerHTML = a.trim!
                # get rendered element(s) and
                # update child link
                c = w3ui '', d.content
                if b
                    # primary
                    @[id].cfg.node = w3ui '#'+b, c
                else
                    # adjacent
                    @[id].node = c
                # check old present
                if old
                    # set display:none
                    c.style.display = 'none'
                    # insert
                    @cfg.node.child.insert c, 0
                else
                    # replace
                    @cfg.node.child.remove!
                    @cfg.node.child.add c
                # done
                true
            # }}}
            attach: (P, event) -> # {{{
                # check parameter
                if event == true
                    # adjacent event source
                    # extract
                    if not (a = @cfg.nav.id) or not (b = @[a])
                        return true
                    # get event data
                    event = b.attach
                # check again
                if typeof! event != 'Array' or not event.length
                    return true
                # prepare attach data
                c = []
                d = []
                for a in event
                    # check for widget
                    if typeof a == 'function'
                        d.push a.call @
                        continue
                    # get nodes (event targets)
                    b = if not a.el
                        then [@cfg.node]
                        else if typeof a.el == 'string'
                            then QUERY a.el, @cfg.node, true
                            else if a.el.length
                                then a.el
                                else [a.el]
                    # set preventDefault flag
                    if not ('preventDefault' of a)
                        # default action is always prevented,
                        # but not for keyboard!
                        a.preventDefault = not /^key.+/.test a.event
                    # set event handler
                    if not ('handler' of a)
                        # bind handler to the node
                        a.handler = P.event.bind @, a
                    # store
                    c.push [a, b]
                # prepare detach routine
                @cfg.detach = ~>
                    # detach events
                    for [a, b] in c
                        b.forEach (b) !-> b.removeEventListener a.event, a.handler
                    for a in d
                        a.detach!
                    # done
                    delete @detach
                    return true
                # prepare event data storage
                @cfg.detach.data = {}
                # attach
                for [a, b] in c
                    b.forEach (b) !-> b.addEventListener a.event, a.handler
                for a in d
                    a.attach!
                # done
                return true
            # }}}
            el: (M, V) -> # {{{
                return PROXY V.ui, {
                    get: (obj, id, prx) ->
                        # check if all roots requested
                        return obj if obj.cfg.id == id
                        # get root id
                        if not (root = M.0)
                            return null
                        # get root element
                        if not (obj = obj[root])
                            return null
                        # check
                        return obj if not id or obj.cfg.id == id
                        return obj[id] if obj[id] and obj[id].cfg
                        # search
                        a = [obj]
                        while a.length
                            # extract node
                            b = a.pop!
                            # iterate
                            for own k,v of b when k != 'cfg' and v and v.cfg
                                # check
                                if v[id] and v[id].cfg
                                    return v[id]
                                # not found
                                a.push v
                        # not found
                        return null
                }
            # }}}
            ###
            list: (id) -> # {{{
                # get node
                x = []
                if not (a = @el[id])
                    return x
                # iterate
                b = [a]
                while b.length
                    # add step
                    x.push b
                    # collect children from last step
                    b = b.map (node) ->
                        # collect
                        c = []
                        for a,b of node when a != 'cfg' and b and b.cfg
                            c.push b
                        # done
                        c
                    # merge
                    b = b.reduce (a, b) -> return a ++ b
                    , []
                # now we have two-dimensional array,
                # lets flatten it
                x = x.reduce (a, b) -> a ++ b
                , []
                # done
                return x
                # }}}
            callMethods: # {{{
                render:
                    active: false
                    followPath: true
                init:
                    active: true
                    cleanup: true
                resize:
                    active: true
                    followPath: true
                refresh:
                    active: true
                    followPath: true
                attach:
                    active: true
                    followPath: true
                detach:
                    active: true
                    reverse: true
                finit:
                    active: false
                    reverse: true
            # }}}
            call: (M) -> # {{{
                return (method, id = '', ...param) ->
                    # prepare
                    param = false if not param.length
                    # get options
                    if not (opts = @callMethods[method])
                        return false
                    # get node list
                    if not (list = @list id)
                        return false
                    # clear inactive node links
                    # {{{
                    if opts.cleanup
                        list.forEach (node) !->
                            # prepare
                            a = node.cfg
                            return if not a.node
                            # get primary node
                            b = if a.context
                                then a.context.cfg
                                else a
                            # check current navigation
                            return if b.parent.cfg.nav.id == b.id
                            # cleanup
                            a.node = null
                    # }}}
                    # filter list
                    # {{{
                    list = list.reduce (a, node) ->
                        # filter nodes without method
                        if not (method of node.cfg)
                            return a
                        # follow navigation path
                        if opts.followPath and node.cfg.parent
                            # get root of the node
                            b = node
                            while b.cfg.parent and b.cfg.parent.cfg.id != 'ui'
                                b = b.cfg.parent
                            # check
                            if b.cfg.id != M.0
                                return a
                        # remove inactive nodes from the list
                        if opts.active and not node.cfg.node
                            return a
                        # include this element
                        a.push node
                        return a
                    , []
                    # check
                    if not list.length
                        return true
                    # reverse order
                    list.reverse! if opts.reverse
                    # }}}
                    # call
                    return list.every (node) ~>
                        # get result
                        a = if param
                            then node.cfg[method].apply node, param
                            else node.cfg[method].call node
                        # check
                        if not a
                            @log method+' failed', node
                        # done
                        return a
            # }}}
            hide: (id, onComplete) !-> # {{{
                # prepare
                if not id or not (list = @list id) or not list.length
                    onComplete!
                    return
                # dont include first (parent) node and
                # set iteration in reverse order
                list = list.slice 1
                list.reverse!
                # create main timeline
                a = new TimelineLite {
                    paused: true
                }
                b = ''
                # iterate
                list.forEach (node) !->
                    # get DOM node
                    return if not (node = @cfg.node)
                    # create timeline
                    c = new TimelineLite {
                        paused: true
                    }
                    # add tweens
                    GSAP.add c, node, @cfg.hide
                    # add marker
                    if not b or b != 'L'+@cfg.level
                        b := 'L'+@cfg.level
                        a.addLabel b
                    # nest
                    a.add c.play!, b
                    # ..
                # add complete routine
                a.add onComplete
                # done
                a.play!
            # }}}
            show: (id1, id0, onComplete) !-> # {{{
                # create main timeline
                x = new TimelineLite {
                    paused: true
                }
                x.addLabel 'turn'
                # TURN transition (old ~> new)
                # {{{
                node   = @el[id1].cfg
                parent = node.parent
                if id0 and (c = parent.cfg.parent)
                    # create list
                    list = [parent]
                    # add adjacent nodes
                    for a,b of c when a != 'cfg' and b.cfg
                        # skip inactive and primary
                        if not b.cfg.node or a == parent.cfg.id
                            continue
                        # add
                        list.push b
                    # walk through list
                    list.forEach (parent) !->
                        # prepare
                        el0  = parent[id0]
                        el1  = parent[id1]
                        turn = parent.cfg.turn
                        flag = !!parent.cfg.context
                        # check old node
                        if flag and (not el0 or not el0.render) and (not el1 or not el1.render)
                            # adjacent parent,
                            # with simple turn effect
                            if turn
                                a = new TimelineLite {paused: true}
                                GSAP.add a, parent.cfg.node, turn
                                x.add a.play!, 'turn'
                            return
                        # get old node
                        if flag
                            # adjacent parent
                            old = el0.node if el0
                        else
                            # primary parent
                            el0 = el0.cfg
                            el1 = el1.cfg
                            old = parent.cfg.node.query '#'+id0, 0, true .0
                        # check transition defined
                        if not turn
                            # add old node remover
                            old and x.add !->
                                parent.cfg.node.child.remove old
                                delete el0.node if el0.node
                            # done
                            return
                        # prioritize turn
                        turn =
                            on: if el1 and el1.turn
                                then el1.turn.on
                                else turn.on
                            off: if el0 and el0.turn
                                then el0.turn.off
                                else turn.off
                        # turn on
                        if el1
                            # create effect
                            a = new TimelineLite {paused: true}
                            # show parent,
                            # if there is no old node
                            if not old and parent.cfg.show
                                GSAP.add a, parent.cfg.node, parent.cfg.show
                            # clear display property (for primary parent)
                            not flag and x.add !->
                                el1.node.style.display = null
                            , 'turn'
                            # turn on new node
                            GSAP.add a, el1.node, turn.on
                            # nest
                            x.add a.play!, 'turn'
                        # turn off
                        if old
                            # create effect
                            a = new TimelineLite {paused: true}
                            # turn off old node
                            GSAP.add a, old, turn.off
                            # hide parent,
                            # if there is no new node
                            if not el1 and parent.cfg.hide
                                GSAP.add a, parent.cfg.node, parent.cfg.hide
                            # nest
                            x.add a.play!, 'turn'
                            # add old node remover
                            x.add !->
                                parent.cfg.node.child.remove old
                                delete el0.node
                # }}}
                # SHOW transition (primary parent)
                # {{{
                # create show-list
                list = @list id1
                # filter
                # remove new node if turn transition set
                list = list.slice 1 if id0
                # active only
                list = list.reduce (a, b) ->
                    a.push b if b.cfg.node
                    return a
                , []
                # add effects
                a = ''
                list.forEach (elem) !->
                    # prepare
                    # create timeline
                    b = elem.cfg
                    c = new TimelineLite {paused: true}
                    # add tweens
                    # reset inline display style
                    c.add !->
                        # get node
                        if b.context
                            c = elem[b.nav.id]
                            c.node.style.display = null if c
                        else
                            b.node.style.display = null
                    # show
                    GSAP.add c, b.node, b.show
                    # add marker
                    if not a or a != 'L'+b.level
                        # update it when level changes,
                        # so nodes at the same level show together
                        a := 'L'+b.level
                        c.addLabel a
                    # nest
                    x.add c.play!, a
                # }}}
                # add complete routine
                x.add onComplete
                # launch
                x.play!
            # }}}
            log: (msg, node) !-> # {{{
                # get route
                a = []
                while node
                    a.push node.cfg.id
                    node = node.cfg.parent
                if a.length
                    msg = '«'+(a.reverse!.join '.')+'» '+msg
                # display
                console.log 'w3ui.app: '+msg
            # }}}
        # }}}
        PRESENTER = # {{{
            init: (M, V, P) -> # {{{
                # initialize methods
                for name,method of PRESENTER
                    if typeof method == 'function' and name != 'init'
                        P[name] = method M, V, P
                # launch
                P.update ->
                    # attach window resize handler
                    window.addEventListener 'resize', P.resize.bind P
                    return true
                # done
                true
            # }}}
            update: (M, V, P) -> # {{{
                # define vars
                busy  = false   # main lock
                lock  = false   # thread lock
                nav   = null    # previous navigation
                id0   = ''      # previous (old)
                id1   = ''      # new
                level = 0       # change level
                rid   = ''      # render root id
                # define helper functions
                cancelThread = (msg) ->
                    # display message
                    console.log msg if msg
                    # unlock
                    lock := false
                    busy := false
                    # break
                    null
                # define thread
                thread = [
                    ->
                        # wait
                        not busy
                    ->
                        # initialize thread
                        # lock
                        busy := true
                        # check navigation to
                        # determine first changed id
                        if nav
                            for a,b in nav when a != M[b]
                                id0 := a
                                id1 := M[b]
                                level := b
                                break
                        else
                            id1 := M.0
                        # cancel if there is no change
                        return cancelThread! if id0 == id1
                        # cancel if change node is undefined
                        if not (a = V.el[id1])
                            # restore navigation
                            M[level] = id0
                            return cancelThread '"'+id1+'" not found'
                        # determine render root
                        b = a.cfg.level - 2
                        b = 0 if b < 0
                        while a.cfg.level > b
                            a = a.cfg.parent
                        rid := a.cfg.id
                        # detach events
                        if not V.call 'detach'
                            return cancelThread 'detach failed'
                        # hide
                        if id0
                            lock := true
                            V.hide id0, !-> lock := false
                        # finalize
                        if not V.call 'finit', id1
                            return cancelThread 'finit failed'
                        # continue
                        true
                    ->
                        # wait
                        not lock
                    ->
                        # render
                        if not V.call 'render', rid, id0
                            return cancelThread 'render failed'
                        # initialize
                        if not V.call 'init'
                            return cancelThread 'init failed'
                        # show
                        lock := true
                        V.show id1, id0, !-> lock := false
                        # continue
                        true
                    ->
                        # wait
                        not lock
                    ->
                        # finalize
                        ['resize' 'refresh' 'attach'].forEach (a) ->
                            V.call a
                        # save navigation and unlock
                        nav  := M.nav.map (a) -> a.id
                        busy := false
                        # done
                        true
                ]
                return (onComplete) !->
                    THREAD if onComplete
                        then thread ++ onComplete
                        else thread
            # }}}
            refresh: (M, V, P) -> # {{{
                return (id = M.0) !->
                    # refresh
                    V.call 'refresh', id
                    V.call 'detach', id
                    V.call 'attach', id
                    # unlock events
                    delete P.event.busy
            # }}}
            resize: (M, V, P) -> # {{{
                return (force) !->
                    # prepare
                    me = P.resize
                    # activate debounce protection (delay)
                    if not force and me.timer
                        # reset timer
                        window.clearTimeout me.timer
                        # set timer
                        me.timer = window.setTimeout (me.bind P), 250
                        return
                    # resize
                    if not V.call 'resize'
                        console.log 'w3ui.app: resize failed'
            # }}}
            event: (M, V, P) -> # {{{
                return (conf, event) ->
                    # prepare
                    me  = P.event
                    cfg = @cfg
                    if conf.preventDefault
                        # we are self-sufficient,
                        # always prevent default action!
                        event.preventDefault!
                    # get event data storage
                    if not cfg.detach or not (dat = cfg.detach.data)
                        return true
                    # check state
                    if me.busy
                        # cancel, event is not delayable
                        return true if not conf.delayed
                        # delay event
                        # dont bubble
                        event.stopPropagation!
                        # check waiter started
                        a = !!me.delayed
                        # create delayed routine
                        me.delayed = me.bind @, conf, event
                        return false if a
                        # speed up animations
                        if typeof me.busy == 'object'
                            me.busy.timeScale 2
                        # start waiter
                        w3ui.THREAD [
                            ->
                                # wait
                                return false if me.busy
                                # process delayed event
                                me.delayed!
                                delete me.delayed
                                # finish
                                true
                        ]
                        return false
                    # process event
                    event.conf = conf
                    event.data = dat
                    me.busy = P.react.call @, M, V, P, event
                    return true
            # }}}
        # }}}
        ###
        return (mvp) -> # {{{
            # check
            if not ('M' of mvp) or not ('V' of mvp) or not ('P' of mvp)
                console.log 'w3ui.app: incorrect parameter'
                return false
            # create MVP objects
            M = PROXY (CLONE MODEL.data <<< mvp.M), MODEL.proxy
            V = ^^VIEW <<< mvp.V
            P = ^^PRESENTER <<< mvp.P
            # add trigger
            document.addEventListener 'DOMContentLoaded', !->
                # initialize view
                if not V.init M, V, P
                    console.log 'w3ui.app: failed to initialize view'
                    return
                # initialize presenter
                if not P.init M, V, P
                    console.log 'w3ui.app: failed to initialize presenter'
                    return
            # done
            true
        # }}}
    # }}}
    DEP = # stand-alone functions {{{
        CLONE: CLONE
        PROXY: PROXY
        THREAD: THREAD
        STATE: STATE
        GSAP: GSAP
        APP: APP
        clearObject: (obj) !-> # {{{
            for own k of obj
                delete obj[k]
        # }}}
        context2d: do -> # {{{
            document.createElement 'canvas' .getContext '2d'
        # }}}
    # }}}
    return new Proxy QUERY, {
        set: (obj, key, val) -> # load widget prototype {{{
            # check
            if key of WIDGET.store
                console.log 'w3ui: widget «'+key+'» already exist, check your code'
                return true
            # store
            WIDGET.store[key] = val
            return true
        # }}}
        get: (obj, key) -> # w3ui accessor {{{
            # stand-alone function
            return DEP[key] if key of DEP
            # widget constructor
            return WIDGET.construct key
        # }}}
    }


# vim: set et ts=4 sw=4 sts=4 fdm=marker fenc=utf-8 ff=dos:
