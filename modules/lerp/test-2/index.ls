######> GREEN corner
do !->
    infos = document.querySelectorAll '.info'
    boxes = document.querySelectorAll '.box'
    ###
    box1 = boxes.0
    box2 = boxes.1
    info = infos.0
    /***
    getStyle = (selector) ->
        rule = CSSRulePlugin.getRule selector
        style = {}
        for prop in rule
            style[_.camelCase prop] = rule[prop]
        return style
    startState = getStyle '.box'
    redState   = getStyle '.red-state'
    greenState = getStyle '.green-state'
    /***/
    config = {
        repeat: -1
        repeatDelay: 1
    }
    duration = 2;
    delay1   = 0;
    delay2   = 2.5;
    ##
    tl1 = new TimelineMax config
    tl1.set box1, {className: 'box'}
    tl1.to box1, duration, {className: '+=green-state'}, delay1
    tl1.to box1, duration, {className: '+=red-state'}, delay2
    ##
    tl2 = new TimelineMax config
    tl2.set box2, {
        width: '100px'
        height: '100px'
        backgroundColor: '#1e90ff'
    }
    tl2.to box2, duration, {
        height: '200px'
        backgroundColor: 'green'
    }, delay1
    tl2.to box2, duration, {
        width: '200px'
        backgroundColor: 'red'
    }, delay2
    ##
    TweenLite.ticker.addEventListener 'tick', !->
        info.innerHTML = "className = #{box1.className}"


######> RED corner
do !->
    b = document.querySelectorAll '.boxMod' .0
    a = new TimelineMax {
        repeat: -1
        repeatDelay: 1
    }
    a.set b, {className: 'boxMod'}
    a.to b, 2, {className: '<green-state'}, 0
    a.to b, 2, {className: '<red-state'}, 2.5



