"use strict"
w3ui = do ->
	w3 =
		console: # {{{
			log: (msg) !->
				a = '%cw3ui: %c'+msg
				console.log a, 'font-weight:bold;color:sandybrown', 'color:aquamarine'
			error: (msg) !->
				a = '%cw3ui: %c'+msg
				console.log a, 'font-weight:bold;color:sandybrown', 'color:crimson'
		# }}}
		promise: (a) -> # {{{
			# create custom promise
			f = null
			p = new Promise (resolve) !->
				f := resolve
			# set initial pending value
			p.pending = a or -1
			# create resolver
			p.resolve = (a) !->
				# if no argument specified, use pending value
				a = p.pending if not arguments.length
				# invalidate pending
				p.pending = 0
				# resolve
				f a
			# done
			return p
		# }}}
		delay: (t = 0, a) -> # {{{
			# create custom promise
			f = null
			p = new Promise (resolve) !->
				f := resolve
			# set initial pending value
			p.pending = a or -1
			# create timer
			x = setTimeout !->
				p.resolve!
			, t
			# create resolver
			p.resolve = (a = p.pending) !->
				clearTimeout x
				p.pending = 0
				f a
			# create cancellator
			p.cancel = !->
				clearTimeout x
				p.pending = 0
				f 0
			# done
			return p
		# }}}
		config: (node, defs = {}) -> # JSON-in-HTML {{{
			# extract and zap contents
			a = node.innerHTML
			node.innerHTML = ''
			# check size, should include <!--{ and }-->
			if a.length <= 9
				return defs
			# strip comment
			a = a.slice 4, (a.length - 3)
			# parse to JSON and combine with defaults
			try
				Object.assign defs, (JSON.parse a)
			catch
				w3ui.console.error 'incorrect config'
			# done
			return defs
		# }}}
		template: (f) -> # HTML-in-JS {{{
			# get function's text and locate the comment
			f = f.toString!
			a = (f.indexOf '/*') + 2
			b = (f.lastIndexOf '*/') - 1
			# tidy up html content and complete
			f = (f.substring a, b).trim!replace />\s+</g, '><'
			return f
		# }}}
		getArrayObjectProps: (a, prop, compact = false) -> # {{{
			# check array-like
			if not a or not (c = a.length)
				return null
			# iterate it and collect properties
			x = []
			i = -1
			while ++i < c
				if (b = a[i]) and prop of b
					x[*] = b[prop]
				else if not compact
					x[*] = null
			# done
			return x
		# }}}
		parse: (template, tags) -> # the dumbest parser {{{
			# prepare
			a = ''
			i = 0
			# search opening marker
			while ~(j = template.indexOf '{{', i)
				# append trailing
				a += template.substring i, j
				i  = j
				j += 2
				# search closing marker
				if (k = template.indexOf '}}', j) == -1
					break
				# check tag length
				if k - j > 16
					a += '{{'
					i += 2
					continue
				# extact tag
				b = template.substring j, k
				# check exists
				if not tags.hasOwnProperty b
					a += '{{'
					i += 2
					continue
				# substitute
				a += tags[b]
				i  = k + 2
			# append remaining
			return a + (template.substring i)
		# }}}
		append: (box, item) -> # {{{
			if not (box instanceof Element)
				if not (box = box.root)
					return null
			if item instanceof Array
				for a in item
					if a instanceof Element
						box.appendChild a
					else if a.root
						box.appendChild a.root
			else if item instanceof Element
				box.appendChild item
			else if item.root
				box.appendChild item.root
			###
			return item
		# }}}
		queryChildren: (parentNode, selector) -> # {{{
			# prepare
			a = []
			if not parentNode or not parentNode.children.length
				return a
			# select all and filter result
			for b in parentNode.querySelectorAll selector
				if b.parentNode == parentNode
					a[*] = b
			# done
			return a
		# }}}
		queryChild: (parentNode, selector) -> # {{{
			# check
			if not parentNode
				return null
			# reuse
			a = w3ui.queryChildren parentNode, selector
			# done
			return if a.length
				then a.0
				else null
		# }}}
		event: # {{{
			# base
			hover: (B, I) -> (e) !-> # {{{
				# prepare
				e.preventDefault!
				# check
				if not B.locked and not B.hovered
					# operate
					B.hovered = true
					B.root.classList.add 'h'
					# callback
					B.onHover I, true, e if B.onHover
			# }}}
			unhover: (B, I) -> (e) !-> # {{{
				# prepare
				e.preventDefault!
				# check
				if B.hovered
					# operate
					B.hovered = false
					B.root.classList.remove 'h'
					# callback
					B.onHover I, false, e if B.onHover
			# }}}
			# TODO
			focus: (B) -> (e) !-> # {{{
				# check
				if B.locked
					# ignore
					e.preventDefault!
					#e.stopImmediatePropagation! # focusin bubbles
				else
					# operate
					B.focused = true
					B.root.classList.add 'f'
					# callback
					B.onFocus true, B if B.onFocus
			# }}}
			unfocus: (B) -> (e) !-> # blur {{{
				# prepare
				e.preventDefault!
				# check
				if B.focused
					# operate
					B.focused = false
					B.root.classList.remove 'f'
					# callback
					B.onFocus false, B if B.onFocus
			# }}}
			slaveFocusInOut: (block, node) -> # {{{
				return [
					(e) !~>
						# focusin handler
						# check
						if block.locked
							# prevent
							e.preventDefault!
							e.stopPropagation!
						else
							# operate
							block.focused = true
							node.classList.add 'f'
							# callback
							if block.onFocus
								block.onFocus true, block
						###
					(e) !~>
						# focusout handler
						# operate
						block.focused = false
						node.classList.remove 'f'
						# callback
						e @, false if e = @onFocus
						###
				]
			# }}}
			slaveFocusAggregator: (block) -> # {{{
				bounce = w3ui.delay!
				return (v, o) ->>
					# bounce
					bounce.cancel! if bounce.pending
					if o and not (await bounce := w3ui.delay 64)
						return false
					# check
					if (w = block.focused) == v
						return false
					# callback
					if o and block.onFocus and not (await block.onFocus v, o)
						return false
					# operate
					if o and block.setFocus
						block.setFocus v
					else
						block.focused = v
						block.root.classList.remove 'f'+w if w
						block.root.classList.add 'f'+v
					# done
					return true
			# }}}
			# accumulators
			onHover: (B, F, t = 100) -> # {{{
				###
				# PURPOSE:
				# - unification of multiple event sources (items)
				# - deceleration of unhover (with exceptions)
				# - total hovered value accumulation (groupping)
				# - forced item unhovering (single argument)
				###
				omap = new WeakMap!
				return (item, flag, e) ->>
					# prepare
					if not (o = omap.get item)
						o = [false, null]
						omap.set item, o
					# check forced unhover
					if arguments.length == 1
						if o.1 and o.1.pending
							o.1.resolve!
							return true
						return false
					# operate
					if flag
						# prevent unhovering and check changed
						if o.1 and o.1.pending
							o.1.cancel!
							return false
						else if o.0
							return true
						# set increment
						o.0 = true
						if ++B.hovered == 1
							B.root.classList.add 'h'
					else
						# check changed and prolong unhovering
						if not o.0
							return true
						else if o.1 and o.1.pending
							o.1.cancel!
						# slowdown
						if not await (o.1 = w3ui.delay t)
							return false
						# set decrement
						o.0 = false
						if not --B.hovered
							B.root.classList.remove 'h'
					# callback
					F item, flag, e
					# done
					return true
			# }}}
			debounce: (F, t = 300, max = 3) -> # {{{
				###
				# PURPOSE:
				# - improved debouncing of the generic event routine
				# - max=0 acts like a standard debouncer
				# - accepts forced calls (no parameter)
				# - suitable for ResizeObserver, pointermove, etc
				###
				timer = w3ui.delay!
				count = 0
				return (e) ->>
					# check observed (non-forced)
					while e
						# check state
						if timer.pending
							# prevent previous call
							timer.cancel!
							# increment counter and check limit reached
							if max and (count := count + 1) > max
								break
						# slowdown
						if await (timer := w3ui.delay t)
							break
						# skip
						return false
					# reset counter and execute callback
					count := 0
					F e
					return true
			# }}}
		# }}}
	ui =
		button: do -> # {{{
			Block = (root, o) !-> # {{{
				# base
				@root    = root
				@label   = w3ui.queryChild root, '.label'
				@cfg     = o.cfg
				# state
				@rect    = null # DOMRect
				@hovered = false
				@focused = false
				@locked  = true
				# traps
				@onHover = o.onHover or null
				@onFocus = o.onFocus or null
				@onClick = o.onClick or null
				@onPress = o.onPress or null
				# handlers
				a = 'addEventListener'
				root[a] 'pointerenter', w3ui.event.hover @, o.onHoverItem
				root[a] 'pointerleave', w3ui.event.unhover @, o.onHoverItem
				root[a] 'focus', w3ui.event.focus @
				root[a] 'blur', w3ui.event.unfocus @
				root[a] 'click', (e) !~>> # {{{
					# prepare
					e.preventDefault!
					e.stopPropagation!
					# check
					if not @locked and @onClick
						# callback
						if (e = @onClick @) instanceof Promise
							# lock
							@locked = e
							@root.disabled = true
							@root.classList.add 'w'
							# wait complete
							if await e
								# unlock
								@root.disabled = @locked = false
								@root.classList.remove 'w'
						else if not e
							# lock
							@locked = w3ui.promise!
							@root.disabled = true
							@root.classList.add 'w'
				# }}}
			Block.prototype =
				lock: (flag = true) !-> # {{{
					# check
					if @locked != flag
						# TODO: unlock busy-wait promise
						# operate
						@root.classList.toggle 'v', !(@locked = flag)
						if flag or ~@current or ~@cfg.intermediate
							@root.disabled = flag
				# }}}
			# }}}
			return (o = {}) -> # {{{
				# construct
				a = document.createElement 'button'
				a.type      = 'button'
				a.disabled  = true
				a.className = 'w3-button'+((o.name and ' '+o.name) or '')
				if o.hint
					a.setAttribute 'title', o.hint
				if o.label
					b = document.createElement 'div'
					b.className   = 'label'
					b.textContent = o.label
					a.appendChild b
				else if o.html
					a.innerHTML = o.html
				# complete
				return new Block a, o
			# }}}
		# }}}
		checkbox: do -> # {{{
			template = w3ui.template !-> # {{{
				/*
				<button type="button" class="sm-checkbox" disabled>
				<svg preserveAspectRatio="none" viewBox="0 0 48 48">
					<circle class="a" cx="24" cy="24" r="12"/>
					<path class="b" d="M24 6a18 18 0 110 36 18 18 0 010-36zm0 6a12 12 0 110 24 12 12 0 010-24z"/>
					<path class="c" d="M24 4a20 20 0 110 40 20 20 0 010-40zm0 2a18 18 0 110 36 18 18 0 010-36z"/>
					<path class="d" d="M48 27v-6H0v6z"/>
					<path class="e" d="M27 48V0h-6v48z"/>
				</svg>
				</button>
				*/
			# }}}
			Block = (root, cfg) !-> # {{{
				# base
				@root = root
				@cfg  = cfg
				# state
				@current  = -2 # -2=initial -1=intermediate, 0=off, 1=on
				@hovered  = false
				@focused  = false
				@locked   = true
				# traps
				@onHover  = null
				@onFocus  = null
				@onChange = null
				# handlers
				@hover = (e) !~>> # {{{
					# pprepare
					e.preventDefault!
					# check
					if not @locked
						# operate
						if not @onHover or (await @onHover @, true)
							@setHovered true
				# }}}
				@unhover = (e) !~>> # {{{
					# prepare
					e.preventDefault!
					# operate
					if not @onHover or (await @onHover @, false)
						@setHovered false
				# }}}
				@focus = (e) !~>> # {{{
					# check
					if @locked
						# try to prevent
						e.preventDefault!
						e.stopPropagation!
					else
						# operate
						if not @onFocus or (await @onFocus @, true)
							@setFocused true
				# }}}
				@unfocus = (e) !~>> # {{{
					# prepare
					e.preventDefault!
					# operate
					if not @onFocus or (await @onFocus @, false)
						@setFocused false
				# }}}
				@click = (e) !~> # {{{
					# prepare
					e.preventDefault!
					e.stopPropagation!
					# check
					if not @locked and (~@current or ~@cfg.intermediate)
						# operate
						@event!
				# }}}
				@event = !~>> # {{{
					# determine new current
					c = if ~(c = @current)
						then 1 - c # switch 0<=>1
						else @cfg.intermediate # escape
					# should be focused
					@root.focus! if not @focused
					# operate
					if not @onChange or (await @onChange @, c)
						@set c
					# done
				# }}}
			Block.prototype =
				init: (v = -1) !-> # {{{
					# set current state
					@set v
					@root.classList.add 'i' if ~@cfg.intermediate
					# set traps
					if a = @cfg.master
						@onHover = a.onHover if not @onHover
						@onFocus = a.onFocus if not @onFocus
					# set events
					a = @root
					b = 'addEventListener'
					a[b] 'pointerenter', @hover
					a[b] 'pointerleave', @unhover
					a[b] 'focusin', @focus
					a[b] 'focusout', @unfocus
					a[b] 'click', @click
					# done
				# }}}
				lock: (flag = true) !-> # {{{
					if @locked != flag
						@root.classList.toggle 'v', !(@locked = flag)
						if flag or ~@current or ~@cfg.intermediate
							@root.disabled = flag
				# }}}
				set: (v) -> # {{{
					# check
					if @current == v
						return v
					# set style
					if (i = @current + 1) >= 0
						@root.classList.remove 'x'+i
					@root.classList.add 'x'+(v + 1)
					# complete
					return @current = v
				# }}}
				setHovered: (v) -> # {{{
					# check
					if @hovered == v
						return false
					# operate
					@hovered = v
					@root.classList.toggle 'h'
					return true
				# }}}
				setFocused: (v) -> # {{{
					# check
					if @focused == v
						return false
					# operate
					@focused = v
					@root.classList.toggle 'f'
					return true
				# }}}
			# }}}
			return (o = {}) ->
				# prepare
				o.intermediate = if o.intermediate
					then o.intermediate
					else -1 # disabled
				# construct
				a = document.createElement 'template'
				a.innerHTML = template
				a = a.content.firstChild # button
				a.innerHTML = o.svg if o.svg
				# create a block
				return new Block a, o
		# }}}
		select: do -> # {{{
			template = w3ui.template !-> # {{{
				/*
				<svg preserveAspectRatio="none" viewBox="0 0 48 48">
					<polygon class="b" points="24,32 34,17 36,16 24,34 "/>
					<polygon class="b" points="24,34 12,16 14,17 24,32 "/>
					<polygon class="b" points="34,17 14,17 12,16 36,16 "/>
					<polygon class="a" points="14,17 34,17 24,32 "/>
				</svg>
				*/
			# }}}
			Block = (root, select) !-> # {{{
				# base
				@root     = root
				@select   = select
				# state
				@current  = -1
				@hovered  = false
				@focused  = false
				@locked   = true
				# traps
				@onHover  = null
				@onFocus  = null
				@onChange = null
				# handlers
				@hover = (e) !~> # {{{
					# fulfil event
					e.preventDefault!
					# operate
					if not @locked and not @hovered
						@hovered = true
						@root.classList.add 'h'
						e @ if e = @onHover
				# }}}
				@unhover = (e) !~> # {{{
					# fulfil event
					e.preventDefault!
					# operate
					if @hovered
						@hovered = false
						@root.classList.remove 'h'
						e @ if e = @onHover
				# }}}
				@focus = (e) !~> # {{{
					if @locked
						# try to prevent
						e.preventDefault!
						e.stopPropagation!
					else if not @focused
						# opearate
						@focused = true
						@root.classList.add 'f'
						e @ if e = @onFocus
				# }}}
				@unfocus = (e) !~> # {{{
					# fulfil event
					e.preventDefault!
					# operate
					if @focused
						@focused = false
						@root.classList.remove 'f'
						e @ if e = @onFocus
				# }}}
				@input = (e) !~> # {{{
					# prepare
					e.preventDefault!
					# check
					if @locked or \
					   ((e = @onChange) and not (e @select.selectedIndex))
						###
						# change is not allowed
						@select.selectedIndex = @current
					else
						# update current
						@current = @select.selectedIndex
				# }}}
			Block.prototype =
				init: (list = null, index = -1) !-> # {{{
					# set options
					if list
						# create options
						for a in list
							b = document.createElement 'option'
							b.textContent = a
							@select.appendChild b
						# set current
						@current = @select.selectedIndex = index
					else
						# reset and clear options
						@current = @select.selectedIndex = -1
						@select.innerHTML = ''
					# set events
					a = @root
					b = if list
						then 'addEventListener'
						else 'removeEventListener'
					###
					a[b] 'pointerenter', @hover
					a[b] 'pointerleave', @unhover
					a[b] 'focusin', @focus
					a[b] 'focusout', @unfocus
					a[b] 'input', @input
				# }}}
				lock: (locked) !-> # {{{
					if @locked != locked
						@root.classList.toggle 'v', !(@locked = locked)
						@select.disabled = locked
				# }}}
				set: (i) -> # {{{
					@current = @select.selectedIndex = i if i != @current
					return i
				# }}}
				get: -> # {{{
					return @current
				# }}}
			# }}}
			return (o = {}) ->
				# create a container
				a = document.createElement 'div'
				a.className = BRAND+'-select'
				a.innerHTML = if o.hasOwnProperty 'svg'
					then o.svg
					else template
				# create a select
				b = document.createElement 'select'
				a.appendChild b
				# create block
				return new Block a, b
		# }}}
		section: do -> # {{{
			Title = (node) !-> # {{{
				@root  = node
				@box   = node = node.firstChild
				@h3    = node.children.0
				@arrow = node.children.1
				@label = @h3.firstChild
			# }}}
			Item = (block, node, parent) !-> # {{{
				# base
				@block  = block
				@node   = node
				@parent = parent
				@config = cfg = JSON.parse node.dataset.cfg
				# controls
				@title    = new Title (w3ui.queryChild node, '.title')
				@extra    = null # title extension
				@section  = sect = w3ui.queryChild node, '.section'
				@children = c = w3ui.queryChildren sect, '.item'
				# construct recursively
				if c
					for a,b in c
						c[b] = new Item block, a, @
				# state
				@hovered = 0 # 1=arrow 2=extra
				@focused = 0
				@opened  = false
				@locked  = true
				# handlers
				hoverBounce = w3ui.delay!
				focusBounce = w3ui.delay!
				@onHover = (e, hovered) ~>> # {{{
					# bounce
					hoverBounce.cancel! if hoverBounce.pending
					if await hoverBounce := w3ui.delay 66
						# determine hover variant
						a = @title.arrow
						x = @extra
						hovered = if not hovered
							then 0
							else if not x or e == a
								then 1 # arrow
								else 2 # extra
						# check
						if hovered != (h = @hovered)
							# operate
							# update value
							@hovered = hovered
							# set children
							if hovered == 1
								x.setHovered false if h
								a.classList.add 'h'
							else if hovered == 2
								x.setHovered true
								a.classList.remove 'h' if h
							else if h == 2
								x.setHovered false
							else
								a.classList.remove 'h'
							# set self
							a = @node.classList
							a.remove 'h'+h if h
							a.add 'h'+hovered if hovered
							# callback
							if (not hovered or not h) and @block.onHover
								@block.onHover @, hovered
					# done
					return false
				# }}}
				@onFocus = (e, focused) ~>> # {{{
					# bounce
					focusBounce.cancel! if focusBounce.pending
					if await focusBounce := w3ui.delay 66
						# determine focus variant
						a = @title.arrow
						x = @extra
						focused = if not focused
							then 0
							else if not x or e == a
								then 1 # arrow
								else 2 # extra
						# check
						if focused != (f = @focused)
							# operate
							@focused = focused
							@node.classList.toggle 'f', !!focused
							# callback
							if @block.onFocus
								@block.onFocus @, focused
					# done
					return true
				# }}}
				@focus = (e) !~> # {{{
					# prepare
					e.preventDefault!
					# operate
					if not @locked
						(e = @title.arrow).classList.add 'f'
						@onFocus e, true
				# }}}
				@unfocus = (e) !~> # {{{
					# prepare
					e.preventDefault!
					# operate
					(e = @title.arrow).classList.remove 'f'
					@onFocus e, false
				# }}}
				@keydown = (e) ~> # {{{
					# check
					if @locked
						return false
					# check
					switch e.keyCode
					case 38,75 # Up,k
						# focus up
						# find arrow above current item
						if e = @searchArrow true
							e.title.arrow.focus!
						###
					case 40,74 # Down,j
						# find arrow below current item
						if e = @searchArrow false
							e.title.arrow.focus!
						###
					case 37,72,39,76 # Left,h,Right,l
						# switch section
						@onSwitch! if @section
						console.log 'open/close section?'
						###
					default
						return false
					# handled
					e.preventDefault!
					e.stopPropagation!
					return true
				# }}}
			Item.prototype =
				init: !-> # {{{
					# set initial state
					@opened = @config.opened
					@title.label.textContent = a if a = @config.name
					# attach title
					b = 'addEventListener'
					a = @title.h3
					a[b] 'pointerenter', @hover a
					a[b] 'pointerleave', @unhover a
					a[b] 'click', @click a
					a = @title.arrow
					a[b] 'pointerenter', @hover a
					a[b] 'pointerleave', @unhover a
					a[b] 'click', @click a
					a[b] 'focusin', @focus
					a[b] 'focusout', @unfocus
					a[b] 'keydown', @keydown
					# set styles
					a = 'e'+((@extra and '1') or '0')
					b = 'o'+((@opened and '1') or '0')
					@node.classList.add a, b
					@title.arrow.classList.add 'v' if @config.arrow
					@extra.root.classList.add 'extra' if @extra
					# recurse to children
					if a = @children
						for b in a
							b.init!
				# }}}
				lock: (flag) -> # {{{
					# check
					if @locked != flag
						# operate
						@locked = flag
						@node.classList.toggle 'v', !flag
						if a = @title
							a.arrow.disabled = flag
						if a = @extra
							a.lock flag
					# recurse to children
					if a = @children
						for b in a
							b.lock flag
					# done
					return flag
				# }}}
				hover: (o) -> (e) !~> # {{{
					# prepare
					e.preventDefault!
					# operate
					if not @locked
						@onHover o, true
				# }}}
				unhover: (o) -> (e) !~> # {{{
					# prepare
					e.preventDefault!
					# operate
					@onHover o, false
				# }}}
				click: (o) -> (e) !~>> # {{{
					# prepare
					e.preventDefault!
					# check
					if not @locked
						# operate
						if @extra and o == @title.h3
							# trigger extra
							@extra.event!
						else if @section
							# switch value
							e = !@opened
							if not @block.onChange or (await @block.onChange @, e)
								@set e
							# should be focused
							@title.arrow.focus! if not @focused
				# }}}
				set: (v) -> # {{{
					# check
					if @opened == v
						return false
					# operate
					@opened = v
					v = (v and 1) or 0
					@node.classList.remove 'o'+(1 - v)
					@node.classList.add 'o'+v
					# done
					return true
				# }}}
				searchArrow: (direction) !-> # {{{
					# WARNING: highly imperative
					if direction
						# UPWARD {{{
						##[A]##
						# drop to upper siblings
						if (a = @).parent
							# prepare
							b = a.parent.children
							c = b.indexOf a
							# find last sibling section
							while --c >= 0
								if b[c].children
									# focus if closed
									if not (a = b[c]).opened
										return a
									# skip to [B]
									break
							# when no sibling sections found,
							# focus to parent
							if !~c
								return a.parent
						##[B]##
						# drop to the last child section of the opened sibling
						while b = a.children
							# prepare
							c = b.length
							# find last child section
							while --c >= 0
								if b[c].children
									# focus if closed
									if not (a = b[c]).opened
										return a
									# continue diving..
									break
							# end with opened section
							# if it doesn't have any child sections
							break if !~c
						# done
						# }}}
					else
						# DOWNWARD {{{
						##[A]##
						# dive into inner area
						if (a = @).opened
							# prepare
							if not (b = a.children)
								return a
							# find first child section
							c = -1
							while ++c < b.length
								if b[c].children
									return b[c]
						##[B]##
						# drop to lower siblings
						while b = a.parent
							# prepare
							c = b.children
							d = c.indexOf a
							# find first sibling section
							while ++d < c.length
								if c[d].children
									return c[d]
							# no sibling sections found,
							# bubble to parent and try again..
							a = a.parent
						# re-cycle focus to the root..
						# }}}
					# done
					return a
				# }}}
				getLastVisible: -> # {{{
					# check self
					if not (a = @children) or not @opened
						return @
					# search recursively
					return a[a.length - 1].getLastVisible!
				# }}}
				getNextVisible: -> # {{{
					# check self
					if @children and @opened
						return @children.0
					# navigate
					a = @
					while b = a.parent
						# get next sibling
						c = b.children
						if (d = c.indexOf a) < c.length - 1
							return c[d + 1]
						# climb up the tree..
						a = b
					# done
					return a
				# }}}
			# }}}
			Block = (root) !-> # {{{
				# base
				@root    = root
				@rootBox = box = root.firstChild
				# controls
				@lines   = w3ui.queryChildren box, 'svg'
				@item    = root  = new Item @, box, null
				@sect    = sect  = {}     # with section (parents)
				@items   = items = {}     # all
				@list    = list  = [root] # all ordered
				# assemble items tree in rendered order
				a = -1
				while ++a < list.length
					if (b = list[a]).children
						sect[b.config.id] = b
						list.push ...b.children
					items[b.config.id] = b
				# state
				@hovered  = false
				@focused  = false
				@locked   = true
				# traps
				@onHover  = null
				@onFocus  = null
				@onChange = null
			###
			Block.prototype =
				init: (title) !-> # {{{
					# set title
					if not @item.config.name and title
						@item.title.label.textContent = title
					# initialize
					@item.init!
				# }}}
				lock: (flag = true) !-> # {{{
					if @locked != flag
						@locked = @item.lock flag
				# }}}
			# }}}
				/***
				S.onRefocus = (i1, i2, direction) ~> # {{{
					# prepare
					a = null
					# check destination
					if i2
						# up/down navigation for root
						if not i1.parent
							# pass to checkbox
							# get item
							if direction
								# last
								a = i1.getLastVisible!
								a = @checks.get a.config.id
							else
								# first
								a = @checks.get i1.children.0.config.id
					else
						# left/right breakout
						# direction doesn't matter for single checkbox
						a = @checks.get i1.config.id
					# custom
					if a and a.checkbox
						a.checkbox.focus!
					# default
					return !!a
				# }}}
				@onFocus = S.onFocus = do ~> # {{{
					p = null
					return (item) ~>>
						# check
						if p and p.pending
							p.resolve false
						# set
						if item.focused
							@focused = true
							@root.classList.add 'f'
						else if await (p := w3ui.delay 60)
							@focused = false
							@root.classList.remove 'f'
						# done
						return true
				# }}}
				@onAutofocus = S.onAutofocus = (node) !~> # {{{
					if not @focused and \
						(a = S.rootItem).config.autofocus
						###
						if a.arrow
							a.arrow.focus!
						else
							a.checks.checkbox.focus!
				# }}}
				/***/
			return (o) ->
				return new Block o
		# }}}
	return Object.assign w3, ui
###
