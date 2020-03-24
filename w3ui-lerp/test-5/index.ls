"use strict"
# redsock ease tests
do !->
    x = window.performance.now!
    while true
        if Math.abs (window.performance.now! - x) > 2*60*1000
            break
    return
    # declare
    # {{{
    state = 0
    nodeMap =
        box: document.querySelectorAll '.box' .0
        target: document.querySelectorAll '.projectile' .0
        graph: document.querySelectorAll '.graphBox' .0
        time: [...(document.querySelectorAll '.duration div')]
        variant: [...(document.querySelectorAll '.variant div')]
        func: [...(document.querySelectorAll '.func div')]
    graph =
        xaxis:
            range: [0, 100]
        yaxis:
            range: [0, 100]
        data:
            {
                x: [0, 100]
                y: [0, 100]
                mode: 'lines+markers'
                type: 'scatter'
                name: 'linear'
                line:
                    color: 'gray'
            }
            {
                x: []
                y: []
                mode: 'lines'
                type: 'scatter'
                name: 'in'
                line:
                    color: 'gray'
            }
            {
                x: []
                y: []
                mode: 'lines'
                type: 'scatter'
                name: 'out'
                line:
                    color: 'gray'
            }
            {
                x: []
                y: []
                mode: 'lines'
                type: 'scatter'
                name: 'in-out'
                line:
                    color: 'gray'
            }
            {
                x: []
                y: []
                mode: 'lines'
                type: 'scatter'
                name: 'out-in'
                line:
                    color: 'gray'
            }
    # }}}
    onUpdate = !-> # {{{
        # update progress
        s = if state == 1
            then @scale
            else 1 - @scale
        nodeMap.target.innerHTML = (100 * s) .|. 0
    # }}}
    tween = # {{{
        {
            duration: 2
            target: nodeMap.target
            onUpdate: onUpdate
            className: '+tested'
            ease: 'linear'
        }
        {
            duration: 2
            target: nodeMap.target
            onUpdate: onUpdate
            className: '-tested'
            ease: 'linear'
        }
    # }}}
    # projectile {{{
    tween = tween.map (a) -> redsock a
    nodeMap.box.addEventListener 'click', !->
        # START button
        # dont interrupt current progress
        a = tween.some (a) -> a.active
        return if a
        # play
        tween[state].play!
        # change state
        state := if state
            then 0
            else 1
    nodeMap.time.forEach (node, index) !->
        node.addEventListener 'click', !->
            # set node class
            nodeMap.time.forEach (node) !-> node.className = ''
            node.className = 'selected'
            # set tween time
            t = parseFloat node.innerHTML
            tween.0.duration = t
            tween.1.duration = t
    # }}}
    # ease variant {{{
    nodeMap.variant.x = 'in'
    nodeMap.variant.forEach (node, index) !->
        node.addEventListener 'click', !->
            # set node class
            nodeMap.variant.forEach (node) !-> node.className = ''
            node.className = 'selected'
            # set ease function variant
            nodeMap.variant.x = node.innerHTML
            v = nodeMap.func.x + '-' + nodeMap.variant.x
            tween.0.ease = v
            tween.1.ease = v
            # update graph
            # determine active curve
            v = ['in' 'out' 'in-out' 'out-in']
            i = 1 + (v.indexOf nodeMap.variant.x)
            # change color
            d = graph.data
            for j from 0 to v.length - 1
                j = j + 1
                d[j].line.color = if j == i
                    then 'red'
                    else 'gray'
            # re-draw
            Plotly.newPlot nodeMap.graph, graph
            # done
    # }}}
    # ease method {{{
    nodeMap.func.x = 'linear'
    nodeMap.func.forEach (node, index) !->
        node.addEventListener 'click', !->
            # set node class
            nodeMap.func.forEach (node) !-> node.className = ''
            node.className = 'selected'
            # set ease function
            nodeMap.func.x = node.innerHTML
            v = nodeMap.func.x + '-' + nodeMap.variant.x
            tween.0.ease = v
            tween.1.ease = v
            # update graph
            # {{{
            # get current ease functions
            v = ['in' 'out' 'in-out' 'out-in']
            x = v.map (variant) ->
                return redsock.ease nodeMap.func.x+'-'+variant
            # clear data
            for i from 1 to graph.data.length - 1
                d = graph.data[i]
                i = i - 1
                d.x = []
                d.y = []
            # set data
            if x.0
                for i from 1 to graph.data.length - 1
                    d = graph.data[i]
                    i = i - 1
                    d.line.color = if nodeMap.variant.x == v[i]
                        then 'red'
                        else 'gray'
                    for j from 0 to 100
                        d.x.push j
                        j = 100 * (x[i] (j / 100))
                        d.y.push j
            # draw
            Plotly.newPlot nodeMap.graph, graph
            # }}}
            # done
    # }}}
    ##


