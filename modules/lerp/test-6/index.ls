"use strict"
do !->
  # base {{{
  currentTween = null
  variant = 7
  nodeMap =
    box: document.querySelectorAll '.box' .0
    projectile: [...(document.querySelectorAll '.projectile')]
    variant: [...(document.querySelectorAll '.variant')]
    code: [...(document.querySelectorAll '.code code')]
  tween = []
  onUpdate = !->
    # determine direction
    d = (@tween.0.clas.last.indexOf 'tested') == -1
    # determine current progress
    a = 100 * @position / @duration
    a = 100 - a if d
    # display
    @target.0.target.innerHTML = parseInt a
  onComplete = !->
    a = nodeMap.box.classList
    b = 'tested'
    if a.contains b
      a.remove b
    else
      a.add b
  ###
  nodeMap.variant[variant].classList.add 'selected'
  # }}}
  # tweens {{{
  /* CODE */
  /* load stylesheet rules */
  redsock.init!

  /* create animation objects */
  /* individual */
  tween.0 = nodeMap.projectile.map (node) ->
    redsock {
      target: node
      duration: 0.5
      className: '!tested'
      onUpdate: onUpdate /* sets progress 0..100 */
    }

  /* chain */
  tween.1 = redsock {
    queue: tween.0
    onComplete: onComplete /* switches background color */
  }

  /* simultaneous */
  tween.2 = redsock {
    queue: tween.0
    positions: 0
    onComplete: onComplete
  }

  /* chain faster */
  tween.3 = redsock {
    clone: tween.1
    duration: 1
  }

  /* simultaneous with ease */
  tween.4 = redsock {
    clone: tween.2
    duration: 1
    ease: 'power2-out-in'
  }

  /* stagger 25% */
  tween.5 = redsock {
    queue: tween.0
    duration: 2
    positions: 25
  }

  /* stagger 10% */
  tween.6 = redsock {
    clone: tween.5
    positions: 10
  }

  /* all fast */
  tween.7 = redsock {
    duration: 4
    queue: [
      tween.1
      tween.2
      tween.3
      tween.4
      tween.5
      tween.6
    ]
  }
  /***/
  # }}}
  # events # {{{
  nodeMap.box.addEventListener 'click', !->
    # block when running
    if currentTween and currentTween.active
      return
    # select tween
    a = tween[variant]
    if variant == 0
      # random individual
      b = Math.floor (Math.random! * a.length)
      a = a[b]
    # play
    currentTween := a.play!
  nodeMap.variant.forEach (node, index) !->
    node.addEventListener 'click', !->
      # clear selection
      nodeMap.variant[variant].classList.remove 'selected'
      # set variant
      nodeMap.variant[index].classList.add 'selected'
      variant := index
  # }}}
  # load # {{{
  # prepare getter
  httpGet = (url, handler) ->
    x = new window.XMLHttpRequest!
    x.overrideMimeType 'text/plain'
    x.onreadystatechange = handler
    x.open 'GET', url, true
    x.send!
  # prepare loader
  loadCode = (url, node, onComplete) !->
    httpGet 'index.ls', !->
      if @readyState == 4 and @status == 200
        # extract code
        c = @responseText
        a = '/* CODE */'
        b = (c.indexOf a) + a.length
        c = c.substr b
        a = '/***/'
        c = c.substr 0, (c.indexOf a)
        # set
        node.innerText = c
        # done
        onComplete!
  # execute
  loadCode 'index.ls', nodeMap.code.0, !->
    hljs.initHighlighting!
  # }}}


