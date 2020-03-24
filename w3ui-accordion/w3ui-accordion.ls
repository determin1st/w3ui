"use strict"
w3ui and w3ui.accordion = {
    options: # {{{
        ORDER: ['panels' 'multiSelect' 'deactivation']
        # BEHAVIOUR
        # allows multiple panel selection
        multiSelect: false
        # hides elements on panel selection:
        # [0]=off
        # [1]=adjacent panels
        # [2]=parent parent's title
        # [3]=all parent titles
        deepDive: 3
        # allows de-activation of a panel
        # when multiSelect is enabled this switch is always on
        deactivation: true
        # deactivates sub-panels
        deactivateChildren: true
        # panel elements order:
        # creates content boxes first, otherwise, titles
        contentBoxFirst: false
        # TODO
        # apply additional animation on adjacent panels
        extraHover: false
        extraActive: false
        # ..
        events:
            hover: null
            unhover: null
            select: null
            selectComplete: null
        # DATA
        # panels=[..,item,..]; item={name:<string>,val:<string>|<panels>}
        panels: null
    # }}}
    data: # {{{
        INIT: ['panels']
        animation: # {{{
            hover: # {{{
                # TITLE
                {
                    duration: 0.4
                    className: '+hovered'
                    ease: 'power2-out'
                }
                # CONTENT
                {
                    position: 0
                    duration: 0.4
                    className: '+hovered'
                    ease: 'power2-out'
                }
                # PANEL CONTAINERS
                {
                    position: 0
                    duration: 0.6
                    className: '+hovered'
                    ease: 'power2-out'
                }
            # }}}
            unhover: # {{{
                # TITLE
                {
                    duration: 0.4
                    className: '-hovered'
                    ease: 'Power2.easeIn'
                }
                # CONTENT
                {
                    position: 0
                    duration: 0.4
                    className: '-hovered'
                    ease: 'Power2.easeIn'
                }
                # PANEL CONTAINERS
                {
                    position: 0
                    duration: 0.4
                    className: '-hovered'
                    ease: 'Power2.easeIn'
                }
            # }}}
            resize: # {{{
                {
                    duration: 0.4
                    css: {}
                    ease: 'Power2.easeInOut'
                }
                ...
            # }}}
            activate: # {{{
                {
                    duration: 0
                    css: {}
                }
                {
                    duration: 0.2
                    className: '+active'
                    ease: 'Power2.easeIn'
                }
                {
                    duration: 0.4
                    className: '+active'
                    ease: 'Power1.easeOut'
                }
                {
                    position: '-=0.3'
                    duration: 0.2
                    className: '+active'
                    ease: 'Power2.easeIn'
                }
            # }}}
            deactivate: # {{{
                {
                    duration: 0.3
                    className: '-active'
                    ease: 'Power2.easeIn'
                }
                {
                    position: '-=0.3'
                    duration: 0.4
                    className: '-active'
                    ease: 'Power1.easeIn'
                }
                {
                    duration: 0.2
                    className: '-active'
                    ease: 'Power2.easeOut'
                }
            # }}}
            enlarge: # {{{
                {
                    duration: 0.4
                    css: {}
                    ease: 'Power2.easeOut'
                }
                ...
            # }}}
            shrink: # {{{
                {
                    duration: 0.4
                    css: {}
                    ease: 'Power1.easeIn'
                }
                ...
            # }}}
            show: # {{{
                {
                    duration: 0.1
                    className: '-hidden'
                    ease: 'Power1.easeOut'
                }
                {
                    duration: 0.3
                    className: '-hidden'
                    ease: 'Power1.easeOut'
                }
                ...
            # }}}
            hide: # {{{
                {
                    duration: 0.3
                    className: '+hidden'
                    ease: 'Power1.easeIn'
                }
                {
                    duration: 0.1
                    className: '+hidden'
                    ease: 'Power1.easeIn'
                }
                ...
            # }}}
            diveOut: # {{{
                {
                    label: 'D0'
                    duration: 4
                    className: '-deepDive'
                    ease: 'Power1.easeOut'
                }
                {
                    position: 'D0'
                    duration: 4
                    className: '-hidden'
                    ease: 'Power1.easeOut'
                }
                {
                    position: 'D0+=2'
                    duration: 4
                    className: '-deepDive'
                    ease: 'Power1.easeOut'
                }
                ...
            # }}}
            diveIn: # {{{
                {
                    # title+content sizer/border
                    duration: 30
                    className: '+hidden'
                    ease: 'Power1.easeIn'
                }
                {
                    # title+content sizer/border
                    duration: 30
                    className: '+hidden'
                    ease: 'Power1.easeIn'
                }
                {
                    # content nodes
                    duration: 30
                    className: '+deepDive'
                    ease: 'Power1.easeIn'
                }
                ...
            # }}}
        # }}}
        events: # {{{
            {
                id: 'hover'
                event: 'pointerenter'
                el: '.title'
            }
            {
                id: 'unhover'
                event: 'pointerleave'
                el: '.title'
            }
            {
                id: 'select'
                event: 'click'
                el: '.title'
            }
        # }}}
    # }}}
    ###
    api: # {{{
        none: true
    # }}}
    create: -> # {{{
        # create panels
        if not @panels.create!
            @log 'failed to create panels'
            return false
        # done
        return true
    # }}}
    resize: !-> # {{{
        if (a = @panels.resize!)
            a.progress 1
    # }}}
    setup: (name, opt) -> # {{{
        switch name
        | 'panels' => @panels = opt
        # done
        return opt
    # }}}
    animation: (name) -> # {{{
        switch name
        | 'resize' =>
            return @panels.resize!
        # done
        return null
    # }}}
    react: (data, event) -> # {{{
        switch (id = data.id)
        | 'hover', 'unhover' =>
            a = event.currentTarget.dataset.id
            b = (id == 'hover')
            @panels.hover a, b
        | 'select' =>
            if (a = event.currentTarget.dataset.id)
                @panels.select a
        | otherwise =>
            return false
        # done
        return true
    # }}}
    ###
    panels: do !->
        initData = (data, parent = null) -> # {{{
            for el,index in data
                # set base
                el.state = w3ui.STATE el
                el.parent = parent
                el.index = index
                el.level = if parent
                    then parent.level + 1
                    else 0
                el.animation = {}
                el.firstElement = (index == 0)
                el.lastElement = (index == data.length - 1)
                el.panelSize = 0
                # set identifier
                if not el.id
                    el.id = el.level+'#'+index
                # set flags
                el.hidden = !!el.hidden
                el.hiddenTitle = !!el.hiddenTitle
                el.active = !!el.active
                el.dived = !!el.dived
                el.disabled = !!el.disabled
                # check sub-panels
                if el.panels
                    # set group options
                    el.panels.deepDive = if 'deepDive' of el
                        then el.deepDive
                        else data.deepDive
                    # recurse
                    if not initData el.panels, el
                        return false
            # done
            return true
        # }}}
        initGroupSize = (data, parent) !-> # {{{
            # determine common/group sizes
            # title gap
            a = data.0.node.0.box
            a = a.borderHeight + a.paddingHeight
            data.titleGap = a
            # panels gap
            a = 0
            if data.length > 1
                for el in data
                    b = el.nodePanel.box
                    a = a + b.borderHeight + b.paddingHeight
            data.panelsGap = a
            # container gap
            a = 0
            if parent
                b = parent.nodeContent.1.box
                a = b.borderHeight + b.paddingHeight
            data.boxGap = a
            # determine individual sizes
            # content boxes
            for a in data
                # prepare
                b = a.nodeContent
                c =
                    'content' of a
                    'panels' of a
                    'contentEnd' of a
                # set values from CSS
                a.contentSize = if c.0
                    then parseInt b.0.style.contentSize
                    else 0
                a.contentEndSize = if c.2
                    then parseInt b.2.style.contentSize
                    else 0
                # recurse to sub-container
                if c.1
                    initGroupSize a.panels, a
        # }}}
        initPanelSize = (data, parentData = data) !-> # {{{
            # prepare
            # collect visible and active sub-panels
            lst0 = []
            lst1 = []
            for el in data when not el.hidden
                lst0.push el if not el.dived
                lst1.push el if el.active
            # calculate total space available
            # get base
            c = data.boxSize
            # check for visible panels
            if lst0.length
                # substract size taken by titles
                c = c - data.titleSize * lst0.length
                # check panel count
                if lst0.length > 1
                    # multiple panels
                    # substract gaps between them
                    c = c - data.panelsGap
            # correct it
            c = 0 if c < 0
            # calculate individual panel sizes
            # {{{
            if (b = lst1.length)
                a = 0
                for el in lst1
                    # check data option
                    if el.size
                        # relative
                        el.state.panelSize = el.size * c / 100.0
                    else
                        # average
                        el.state.panelSize = c / b
                    # increase total
                    a = a + el.panelSize
                # check totals defference
                a = c - a
                if (Math.abs a) > 0.001
                    # correct it
                    # calculate medium delta
                    a = a / b
                    # apply
                    for el in lst1
                        el.state.panelSize = el.panelSize + a
                    # check for error
                    # fix negative (detect positive)
                    a = 0
                    for el in lst1 when el.panelSize < 0
                        # increase negative delta
                        a = a + el.panelSize
                        # fix
                        el.state.panelSize = 0
                    # check for error
                    # fix positive
                    if a < 0
                        # collect positive
                        c = []
                        for el in lst1 when el.panelSize > 0
                            c.push el
                        # calculate medium negative delta
                        a = a / c.length
                        # fix
                        for el in c
                            el.state.panelSize = el.panelSize + a
            # }}}
            # calculate group size
            # {{{
            for el in lst1 when (a = el.panels)
                # sub-panel container
                if el.dived
                    # ..takes all panel space
                    a.boxSize = el.panelSize
                else if el.contentSize or el.contentEndSize
                    # ..relative to other content
                    b = 100 - el.contentSize - el.contentEndSize
                    b = el.panelSize * b / 100.0
                    a.boxSize = b - a.boxGap
                else
                    # ..takes all content space
                    a.boxSize = el.panelSize - a.boxGap
                # title
                b = parentData.titleSize
                if b * lst0.length > el.panelSize
                    if (b = el.panelSize / lst0.length) < 1
                        b = 0
                a.titleSize = b
                # title font
                b = parentData.titleFontSize
                if (c = a.titleSize - parentData.titleGap) > 0
                    b = c if b > c
                else
                    b = 0
                a.titleFontSize = b
            # }}}
            # recurse
            for el in lst1 when el.panels
                initPanelSize el.panels, data
        # }}}
        initAnimations = (data, animation) !-> # {{{
            for el in data
                # individual
                for a,b of animation
                    el.animation[a] = getAnimation el, a, animation
                # group
                el.animation.hovering = new TimelineLite {}
                # sub-panels
                if el.panels
                    initAnimations el.panels, animation
        # }}}
        createNodes = (data, opts, box) !-> # {{{
            # prepare
            # list of visible elements
            list = []
            # panel container
            if not box
                box = w3ui document.createElement 'div'
                box.class.add 'box'
            # create panels
            for el,index in data
                # collect visible
                if not el.hidden
                    list.push el
                # create panel elements
                # {{{
                a = Array 11 .fill 0 .map ->
                    document.createElement 'div'
                # wrap and store
                el.nodeParent = box
                el.nodePanel = w3ui a.0         # primary container
                el.nodeBox = w3ui [a.1, a.2]    # sizers
                el.node = w3ui [a.3, a.4]       # border boxes
                el.nodeTitle = w3ui [a.5, a.6, a.7]
                el.nodeContent = w3ui [a.8, a.9, a.10]
                el.nodes = w3ui a
                # assemble
                el.node.0.child.add el.nodeTitle
                el.node.1.child.add el.nodeContent
                el.nodeBox.0.child.add el.node.0
                el.nodeBox.1.child.add el.node.1
                if el.contentBoxFirst or opts.contentBoxFirst
                    el.nodePanel.child.add el.nodeBox.1
                    el.nodePanel.child.add el.nodeBox.0
                else
                    el.nodePanel.child.add el.nodeBox
                box.child.add el.nodePanel
                # }}}
                # set attributes
                # {{{
                el.nodePanel.class = 'panel'
                el.nodeBox.0.class = 'titleSizer'
                el.nodeBox.1.class = 'contentSizer'
                el.node.0.class = 'title'
                el.node.1.class = 'content'
                el.nodeTitle.forEach (el, index) !->
                    el.class = 'box N'+index
                el.nodeContent.classAdd 'box'
                if el.hidden
                    el.nodePanel.class.add 'hidden'
                    el.active = false
                if el.active
                    el.nodes.classAdd 'active'
                if el.disabled
                    el.nodes.classAdd 'disabled'
                # set identifiers
                el.nodes.props.dataId = el.id
                # set EVEN/ODD style marker
                a = if el.level % 2 == 0
                    then 'EVEN'
                    else 'ODD'
                el.nodes.classAdd a
                # set title/content order marker
                a = if el.contentBoxFirst or opts.contentBoxFirst
                    then 'ORDER_B'
                    else 'ORDER_A'
                el.node.classAdd a
                # set first/last element markers
                if el.firstElement
                    a = 'FIRST'
                    el.nodePanel.class.add a
                    el.node.classAdd a
                if el.lastElement
                    a = 'LAST'
                    el.nodePanel.class.add a
                    el.node.classAdd a
                # set deep dive
                if data.deepDive
                    el.nodePanel.class.add 'deepDive'
                # content markers
                # prepare
                a = el.nodeContent
                b =
                    'content' of el
                    'panels' of el
                    'contentEnd' of el
                # set
                if b.0
                    a.0.class.add 'A'
                    if b.1 or b.2
                        a.0.class.add 'FIRST'
                    else
                        a.0.class.add 'SINGLE'
                if b.1
                    a.1.class.add 'B'
                    if not b.0 and not b.2
                        a.1.class.add 'SINGLE'
                    else
                        if not b.0
                            a.1.class.add 'FIRST'
                        if not b.2
                            a.1.class.add 'LAST'
                if b.2
                    a.2.class.add 'A'
                    if b.0 or b.1
                        a.2.class.add 'LAST'
                    else
                        a.2.class.add 'SINGLE'
                # }}}
                # set content
                # {{{
                if el.title
                    el.nodeTitle.1.html = el.title
                ###
                a = el.nodeContent
                # TOP
                if 'content' of el
                    a.0.html = el.content
                # BOTTOM
                if 'contentEnd' of el
                    a.2.html = el.contentEnd
                # }}}
                # recurse to sub-panels
                if el.panels
                    createNodes el.panels, opts, el.nodeContent.1
            # set container's level marker
            box.class.add 'L'+data.0.level
        # }}}
        getItem = (id, data) -> # {{{
            # search
            for el in data when el.id == id
                return el
            # recurse
            for el in data when el.panels
                return a if (a = getItem id, el.panels)
            # not found
            return null
        # }}}
        getItemList = (data) -> # {{{
            # check
            if not data
                return []
            # initialize
            list = data
            # iterate and recurse
            for a in data when a.panels
                list = list ++ getItemList a.panels
            # done
            return list
        # }}}
        getAnimation = (el, animName, animData) !-> # {{{
            # initialize
            a = w3ui.CLONE animData[animName]
            switch animName
            | 'hover', 'unhover' =>
                # {{{
                a.0.node = el.nodeTitle.nodes
                a.1.node = el.nodeContent.nodes
                a.2.node = el.node.nodes ++ el.nodePanel.nodes
                a = w3ui.GSAP.queue a
                # }}}
            | 'activate' =>
                # {{{
                a.0.node = el.nodeBox.1.node
                a.1.node = el.nodeBox.0.nodes ++ el.node.nodes ++ el.nodeTitle.nodes
                a.2.node =
                    el.nodeBox.1.node
                    el.nodePanel.node
                a.3.node = el.nodeContent.nodes
                # }}}
            | 'deactivate' =>
                # {{{
                a.0.node = el.nodeContent.nodes
                a.1.node =
                    el.nodeBox.1.node
                    el.nodePanel.node
                a.2.node = el.nodeBox.0.nodes ++ el.node.nodes ++ el.nodeTitle.nodes
                # }}}
            | 'resize', 'enlarge', 'shrink' =>
                # {{{
                a.0.node = el.nodeBox.1.node
                # }}}
            | 'show' =>
                # {{{
                a.0.node = el.nodePanel.node
                a.1.node =
                    el.nodeBox.0.node
                    el.node.0.node
                # }}}
            | 'hide' =>
                # {{{
                a.0.node =
                    el.nodeBox.0.node
                    el.node.0.node
                a.1.node = el.nodePanel.node
                # }}}
            | 'diveOut' =>
                # {{{
                a.0.node = el.nodePanel.node
                a.1.node = el.nodeBox.nodes ++ el.node.nodes
                a.2.node = el.nodeContent.nodes
                # }}}
            | 'diveIn' =>
                # {{{
                a.0.node = el.nodeBox.nodes ++ el.node.nodes
                a.1.node = el.nodeContent.nodes
                # }}}
            # store
            return a
        # }}}
        createHoverAnimation = (data) -> # {{{
            # check data
            if not data or not data.length
                return null
            # iterate
            b = []
            for el in data
                # check state
                if el.hovered == el.nodePanel.class.has 'hovered'
                    continue
                # get target animation
                a = if el.hovered
                    then el.animation.hover
                    else el.animation.unhover
                # collect
                b.push a.invalidate!
            # check
            if not b.length
                return null
            # create animation
            a = new TimelineLite {
                paused: true
            }
            for el in b
                a.add el.play!, 0
            # done
            return a
        # }}}
        stopHoverAnimation = (data) !-> # {{{
            for el in data
                a = el.animation
                if a.hovering.isActive!
                    a.hovering.progress 1
        # }}}
        createResizeAnimation = (data) -> # {{{
            # prepare
            anim = []
            animFirstClass = []
            # collect animations
            # panels
            a = []
            for el in data when el.state.panelSize
                # determine the difference and
                # get target animation
                if (el.panelSize - el.state.$panelSize) > 0
                    b = el.animation.enlarge
                else
                    b = el.animation.shrink
                    animFirstClass.push el.id
                # initialize it
                c = {}
                c['--panel-size'] = el.panelSize + 'px'
                if el.panels
                    # sub-panel sizing of title
                    c['--title-size'] = data.titleSize + 'px'
                    c['--title-font-size'] = data.titleFontSize + 'px'
                # set parameter and store
                b.0.to.css = c
                a.push w3ui.GSAP.queue b
            # store
            if (a = w3ui.GSAP.joinTimelines a)
                anim.push a
            # sub-panels
            a = []
            b = []
            # recurse
            for el in data when el.panels
                if (c = createResizeAnimation el.panels)
                    # check ORDER
                    if (animFirstClass.indexOf el.id) < 0
                        b.push c
                    else
                        a.push c
            # store
            if (a = w3ui.GSAP.joinTimelines a)
                anim.unshift a
            if (b = w3ui.GSAP.joinTimelines b)
                anim.push b
            # done
            # check none
            if not anim.length
                return null
            # check single
            if anim.length < 2
                return anim.0
            # combine
            return w3ui.GSAP.joinTimelines anim, true
        # }}}
        createRefreshAnimation = (data) -> # {{{
            # prepare
            anim = []
            animFirstClass = []
            # stop individual animations
            stopHoverAnimation data
            # collect animations
            # panels
            # {{{
            a = []
            b = []
            for el in data
                # read state changes
                d =
                    el.state.hidden
                    el.state.active
                    el.state.dived
                    el.state.panelSize
                # check HIDDEN
                if d.0
                    # get target animation
                    c = if el.hidden
                        then el.animation.hide
                        else el.animation.show
                    # store it
                    a.push w3ui.GSAP.queue c
                # check ACTIVE
                if d.1
                    # get target animation and
                    # initialize it
                    if el.active
                        c = el.animation.activate
                        c.0.to.css['--panel-size'] = el.panelSize + 'px'
                    else
                        c = el.animation.deactivate
                        animFirstClass.push el.id
                    # store it
                    a.push w3ui.GSAP.queue c
                # check DIVED
                if d.2
                    # get traget animation
                    c = if el.dived
                        then el.animation.diveIn
                        else el.animation.diveOut
                    # store it
                    a.push w3ui.GSAP.queue c
                    animFirstClass.push el.id
                # check SIZE
                if d.3 and (not d.2 or not el.dived)
                    # determine the difference and
                    # get target animation
                    if (el.panelSize - el.state.$panelSize) > 0
                        c = el.animation.enlarge
                    else
                        c = el.animation.shrink
                        animFirstClass.push el.id
                    # initialize it
                    e = {}
                    if not d.0 or not el.active
                        # sizing is not necessary
                        # if there is an activation/diving
                        e['--panel-size'] = el.panelSize + 'px'
                    if el.panels
                        # sub-panel sizing of title
                        e['--title-size'] = data.titleSize + 'px'
                        e['--title-font-size'] = data.titleFontSize + 'px'
                    # check empty
                    if Object.keys e .length
                        # set parameter and store
                        c.0.to.css = e
                        a.push w3ui.GSAP.queue c
            # store
            if (a = w3ui.GSAP.joinTimelines a)
                anim.push a
            if (b = w3ui.GSAP.joinTimelines b)
                anim.push b
            # }}}
            # sub-panels
            # {{{
            a = []
            b = []
            for el in data when el.panels
                # recurse
                if (c = createRefreshAnimation el.panels)
                    # check ORDER
                    if (animFirstClass.indexOf el.id) < 0
                        b.push c
                    else
                        a.push c
            # store
            if (a = w3ui.GSAP.joinTimelines a)
                anim.unshift a
            if (b = w3ui.GSAP.joinTimelines b)
                anim.push b
            # }}}
            # done
            # check none
            if not anim.length
                return null
            # check single
            if anim.length < 2
                return anim.0
            # combine
            return w3ui.GSAP.joinTimelines anim, true
        # }}}
        return !->
            DATA = []
            create = ~> # {{{
                # check
                if not DATA.length
                    return true
                # create elements
                createNodes DATA, @options
                # initialize animations
                initAnimations DATA, @data.animation
                # add to the DOM
                @node.child.add DATA.0.nodeParent
                return true
            # }}}
            destroy = !~> # {{{
                if DATA.length
                    # remove from DOM
                    @node.child.remove DATA.0.nodeParent
                    # remove data
                    DATA.length = 0
                    # remove props
                    delete DATA.sizes
            # }}}
            resize = ~> # {{{
                # initialize
                # {{{
                initGroupSize DATA
                # pirmary container
                a = DATA.0.nodeParent.box.innerHeight
                DATA.boxSize = if a < 1
                    then 0
                    else a
                # title font
                if (a = @node.style.titleFontSize) == 0
                    # inherit from accordion
                    a = @node.style.fontSize
                else if typeof a == 'string'
                    # convert value to pixels
                    b = DATA.0.nodeTitle.1.style
                    b.fontSize = a
                    a = b.fontSize
                    b.fontSize = null
                # ok
                DATA.titleFontSize = a
                # title
                # get size
                if (a = @node.style.titleSize) == 0
                    # use font as a base
                    a = DATA.titleFontSize + DATA.titleGap
                else if typeof b == 'string'
                    # convert value to pixels
                    b = DATA.0.nodeTitle.1.style
                    b.height = a
                    a = b.height
                    b.height = null
                # ok
                DATA.titleSize = a
                # apply corrections
                # title
                a = DATA.boxSize - DATA.panelsGap
                if a < DATA.titleSize * DATA.length
                    DATA.titleSize = a / DATA.length
                # title font
                a = DATA.titleSize - DATA.titleGap
                if DATA.titleFontSize > a
                    DATA.titleFontSize = a
                # }}}
                # re-calculate panel sizes
                initPanelSize DATA
                # create animation for..
                # root box
                b = @data.animation.resize
                b.0.to.css = {
                    '--title-size': DATA.titleSize + 'px'
                    '--title-font-size': DATA.titleFontSize + 'px'
                }
                b = w3ui.GSAP.queue b, DATA.0.nodeParent.node
                # panels
                if not (a = createResizeAnimation DATA)
                    return b
                # combine
                a.add b.play!, 0
                # done
                return a
            # }}}
            hover = (id, state) !~> # {{{
                # get panel
                if not (panel = getItem id, DATA)
                    return
                # check necessity
                if panel.disabled or state == panel.hovered
                    return
                # change state
                panel.hovered = state
                # animate
                if DATA.selecting
                    # delay
                    # initialize and add element to queue
                    DATA.hovering = [] if not DATA.hovering
                    DATA.hovering.push panel
                else
                    # instant change
                    # prepare
                    a = panel.animation
                    b = if panel.hovered
                        then a.hover
                        else a.unhover
                    # play
                    a.hovering.kill!clear!
                    a.hovering.add b.invalidate!play!
                /***
                # TODO
                # additional animation
                if @options.hoverMore
                    # get adjacent panels
                    panel = if panel.parent
                        then panel.parent.panels
                        else DATA
                    # iterate
                    for el in panel when not el.hidden and not el.disabled
                        a = el.animation
                        b = el.hovered
                        # stop animation
                        a.hover.kill!
                        a.unhover.kill!
                        # get target animation
                        c = if b
                            then a.hover
                            else a.unhover
                        # animate
                        c.invalidate.play 0
                /***/
            # }}}
            select = (id) !~> # {{{
                # get panel
                if not (panel = getItem id, DATA)
                    return
                # check allowed
                if panel.disabled or
                   (not @options.multiSelect and panel.active and not @options.deactivation)
                    return
                # check lock
                if (a = DATA.selecting)
                    # cancel operation
                    if a == true
                        return
                    # unlock
                    a.progress 1
                    stopSelect true
                # lock
                DATA.selecting = true
                # change state
                # {{{
                if panel.active
                    # DEACTIVATE
                    # set current element
                    panel.state.active = false
                    # get parent data (adjacent panels)
                    a = if panel.parent
                        then panel.parent.panels
                        else DATA
                    # set children
                    if @options.deactivateChildren and panel.panels
                        for b in getItemList panel.panels
                            b.state.active = false
                            b.state.dived = false
                    # check diving
                    if a.deepDive
                        # show adjacent panels
                        for b in a
                            b.state.hidden = false
                        # reset dive flag for parents
                        if a.deepDive > 1 and (b = panel.parent)
                            # one
                            b.state.dived = false
                            # two
                            if a.deepDive < 3 and (b = b.parent)
                                b.state.dived = false
                else
                    # ACTIVATE
                    # set current element
                    panel.state.active = true
                    # get parent data
                    a = if panel.parent
                        then panel.parent.panels
                        else DATA
                    # check multi-selection
                    if not @options.multiSelect
                        # deactivate adjacent panels
                        for b in a when b.active and b != panel
                            # current
                            b.state.active = false
                            # sub-panels
                            if b.panels and @options.deactivateChildren
                                # iterate
                                for b in getItemList b.panels
                                    b.state.active = false
                        # check diving
                        if a.deepDive
                            # hide adjacent panels
                            for b in a when b != panel
                                b.state.hidden = true
                            # check deep diving
                            if a.deepDive > 1 and (b = panel.parent)
                                # all parents
                                if a.deepDive > 2
                                    do
                                        b.state.dived = true
                                    while (b = b.parent)
                                # previous parent
                                else if a.parent
                                    a.parent.state.dived = true
                # }}}
                # re-calculate sizes
                initPanelSize DATA
                # create animation
                if not (a = createRefreshAnimation DATA)
                    DATA.selecting = false
                    return
                # add unlocker
                a.add stopSelect
                # animate
                DATA.selecting = a.play!
            # }}}
            stopSelect = (forced) !-> # {{{
                # check
                if (list = DATA.hovering)
                    # finish previous
                    if forced and (a = list.animation)
                        a.progress 1
                        delete list.animation
                    # create animation
                    else if list.length and (a = createHoverAnimation list)
                        # delayed
                        # clear list
                        list.length = 0
                        # add finisher (self-recurse)
                        a.add stopSelect
                        # store
                        list.animation = a
                        # done
                        a.play!
                        return
                    # cleanup
                    else if list.animation
                        delete list.animation
                # unlock
                DATA.selecting = false
            # }}}
            ### {{{
            Object.defineProperty @, 'panels', {
                set: (data) !->
                    # reset data
                    DATA.length = 0
                    # check
                    if data
                        # set first level options
                        data.deepDive = @options.deepDive
                        # initialize
                        if initData data
                            DATA := data

                get: do ->
                    api = w3ui.PROXY {
                        create
                        destroy
                        resize
                        hover
                        select
                    }, {
                        get: (api, key) ->
                            return api[key] if key of api
                            return if key
                                then getItem key, DATA
                                else DATA
                    }
                    return -> api
            }
            # }}}
}


# vim: set et ts=4 sw=4 sts=4 fdm=marker fenc=utf-8 ff=dos:
