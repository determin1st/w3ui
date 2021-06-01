"use strict"
w3ui = do ->
	# check requirements {{{
	# TODO: possess browser apis
	# TODO: secure loader?
	# TODO:
	# - w3ui focus aggregator
	# - w3ui dropdown
	# - rename section => treeview
	# - category count display (extra)
	# - static paginator max-width auto-calc
	# }}}
	# prepare {{{
	# possess empty objects without a prototype (theoretically better accessed)
	w3ui    = (Object.create null)
	events  = (Object.create null)
	blocks  = (Object.create null)
	Console = (BRAND, DEBUG) !->
		@brand      = BRAND
		@brandStyle = 'font-weight:bold;color:skyblue'
		@logStyle   = 'color:aquamarine'
		@errorStyle = 'color:hotpink'
		@isDebug    = DEBUG
	Console.prototype =
		new: (brand, debug) ->
			retrun new Console brand, debug
		log: (msg) !->
			msg = '%c'+@brand+': %c'+msg
			console.log msg, @brandStyle, @logStyle
		error: (msg) !->
			msg = '%c'+@brand+': %c'+msg
			console.log msg, @brandStyle, @errorStyle
		debug: (e) !->
			console.log e if @isDebug
	# }}}
	Object.assign w3ui, { # {{{
		console: new Console 'w3ui', true
		metaconstruct: do -> # {{{
			map = new WeakMap!
			construct = (props) -> !->
				for prop in props
					@[prop] = null
			return (props) ->
				if not (a = map.get props)
					map.set props, (a = construct props)
				return a
		# }}}
		assign: (cfg, defs) -> # {{{
			if defs and defs instanceof Array
				defs = new w3ui.metaconstruct defs
			if cfg and defs
				for a of defs when cfg.hasOwnProperty a
					defs[a] = cfg[a]
			return if defs
				then defs
				else Object.create null
		# }}}
		factory: (name, Block) -> (o = {}) -> # JSON-in-HTML {{{
			# check variant
			if o.root
				# SSR: use DOM as a source of truth
				# determine class
				o.className = o.root.className or 'w3ui '+name
				# extract configuration (JSON HTML comment)
				if (box = o.root.firstChild) and \
				   (cfg = box.innerHTML)
					###
					# zap box contents
					# https://stackoverflow.com/questions/3955229/remove-all-child-elements-of-a-dom-node-in-javascript
					while box.firstChild
						box.removeChild box.lastChild
					# check proper length of the string,
					# it must include at least 9 chars, <!--{ and }-->
					if cfg.length > 9
						try
							# config correctness is assumed, so,
							# strip and parse text into object
							cfg = cfg.slice 4, (cfg.length - 3)
							cfg = JSON.parse cfg
						catch
							w3ui.console.debug 'incorrect JSON-in-DOM'
							cfg = {}
						# merge specified (CSR) over extracted (SSR)
						o.cfg = if o.cfg
							then Object.assign cfg, o.cfg
							else cfg
				###
			else
				# CSR: use options as a source of truth
				# determine class
				o.className = o.className or 'w3ui '+name
				# create base DOM block:
				# <div class="{className}" style="{style}">
				#   <div><!--{opts}--></div>
				# </div>
				o.root = document.createElement 'div'
				o.root.appendChild (box = document.createElement 'div')
				# set class
				o.root.className = o.className
				# set style
				if o.style
					switch typeof o.style
					case 'object'
						# convert object to string
						a = ''
						for b of o.style
							a += a+':'+o.style[b]+';'
						o.root.setAttribute 'style', a
					case 'string'
						# correct type
						o.root.setAttribute 'style', o.style
				# export configuration back to the DOM,
				# this probably might be requested in the future
				if o.cfg and o.export
					switch typeof opts
					case 'object'
						# insert as HTML comment
						box.innerHTML = '<!--'+(JSON.stringify o.cfg)+'-->'
					case 'string'
						# correct context assumed
						box.innerHTML = o.cfg
						o.cfg = {}
			# construct
			return new Block o
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
		template: (f) -> # HTML-in-JS {{{
			# get function's text and locate the comment
			f = f.toString!
			a = (f.indexOf '/*') + 2
			b = (f.lastIndexOf '*/') - 1
			# tidy up html content and complete
			f = (f.substring a, b).trim!replace />\s+</g, '><'
			return f
		# }}}
		parse: (template, tags) -> # micro-mustache parser {{{
			###
			# the concept is very obvious:
			# - mustache tags markup replacement blocks
			# - logicless
			# - avoid false marker matches
			###
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
		queryChildren: (node, selector) -> # {{{
			# prepare
			a = []
			if not node or not node.children.length
				return a
			# select all and filter result
			for b in node.querySelectorAll selector
				if b.parentNode == node
					a[*] = b
			# done
			return a
		# }}}
		queryChild: (node, selector) -> # {{{
			# check
			if not node
				return null
			# reuse
			a = w3ui.queryChildren node, selector
			# done
			return if a.length
				then a.0
				else null
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
		debounce: (f, t = 100, max = 3) -> # {{{
			###
			# PURPOSE:
			# - improved debouncing of a function (event handler)
			# - standard debouncing with max=0 (no penetration)
			# - forced/immediate calls (reduced parameter count)
			###
			timer = w3ui.delay!
			count = 0
			return (...e) ->>
				# check observed (non-forced)
				while e.length == f.length
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
				# reset counter
				count := 0
				# execute callback
				return f.apply null, e
		# }}}
	}
	# }}}
	Object.assign events, do -> # {{{
		# {{{
		# prepare
		nodeEvents  = new WeakMap! # DOM node => events
		blockEvents = new WeakMap! # block => events
		# create constructor
		Events = w3ui.metaconstruct [
			'hover' 'focus' 'click' 'mmove'
		]
		getEvents = (node) ->
			# extract
			if not (e = nodeEvents.get node)
				# initialize
				nodeEvents.set node, (e = new Events!)
			# complete
			return e
		# }}}
		return {
			attach: (block, o) !-> # {{{
				# extract
				if not (e = blockEvents.get block)
					# initialize
					blockEvents.set block, (e = new Events!)
				# operate
				for a of e when o.hasOwnProperty a
					# detach already attached node
					events[a] block.root if e[a]
					# always attached
					events[a] block, o[a]
					e[a] = 1# node attached
			# }}}
			hover: (item, f, o) !-> # {{{
				if item instanceof HTMLElement
					# DOM NODE
					# detach already attached
					if a = (e = getEvents item).hover
						e.hover = null
						item.removeEventListener 'pointerenter', a.0
						item.removeEventListener 'pointerleave', a.1
					# check
					return if not f
					# create handlers
					o = item if arguments.length < 3
					a = e.hover = [
						(e) !->
							if e.pointerType == 'mouse'
								e.preventDefault!
								f o, 1, e
						(e) !->
							if e.pointerType == 'mouse'
								e.preventDefault!
								f o, 0, e
					]
					# attach
					item.addEventListener 'pointerenter', a.0
					item.addEventListener 'pointerleave', a.1
				else
					# BLOCK OBJECT
					# reset state
					item.hovered = 0
					# create and attach handler
					events.hover item.root, (root, v, e) !->
						# hovering of locked is not allowed, but
						# unhovering is always fine
						if not item.locked or not v
							# operate
							item.hovered = v
							root.classList.toggle 'h', v
							# callback
							f o, v, e if f
			# }}}
			hovers: (B, F, t = 100, N = B.root) -> # {{{
				###
				# PURPOSE:
				# - aggregation of multiple event sources
				# - deceleration of unhover (with exceptions)
				# - hovered value accumulation
				###
				omap = new WeakMap!
				return (item, v, e) ->>
					# prepare
					if not (o = omap.get item)
						o = [0, w3ui.delay!]
						o.1.cancel!
						omap.set item, o
					# check
					if not e
						# forced call
						if not v
							# instant unhover
							# check
							if not o.0
								# already unhovered
								return false
							else if o.1.pending
								# prevent lazy unhovering
								o.1.cancel!
							# set
							o.0 = 0
						else if v == -1
							# activate or deactivate instant unhover
							# check
							if not o.0
								return false
							# set
							o.0 = if o.0 == -1
								then 1
								else -1
							# done, no callback
							return true
						else
							# unsupported
							return false
					else if v == 1
						# instant hover
						# check
						if o.1.pending
							# prevent unhovering
							o.1.cancel!
							return true
						else if o.0
							# already hovered
							return false
						# set
						o.0 = 1
					else
						# lazy unhover
						# check
						if not o.0
							# already unhovered
							return false
						if o.1.pending
							# prolong unhovering
							o.1.cancel!
						# slowdown
						if ~o.0 and not await (o.1 = w3ui.delay t)
							return false
						# set
						o.0 = 0
					# accumulate
					if o.0
						# increment
						if ++B.hovered == 1 and N
							N.classList.add 'h'
					else
						# decrement
						if --B.hovered == 0 and N
							N.classList.remove 'h'
					# callback
					F item, v, e
					# done
					return true
			# }}}
			focus: (item, f, o) !-> # {{{
				if item instanceof HTMLElement
					# DOM NODE
					# detach already attached
					if a = (e = getEvents item).focus
						e.focus = null
						item.removeEventListener 'focus', a.0
						item.removeEventListener 'blur', a.1
					# check
					return if not f
					# create handlers
					o = item if arguments.length < 3
					a = e.focus = [
						(e) !-> f o, 1, e
						(e) !-> f o, 0, e
					]
					# attach handlers
					item.addEventListener 'focus', a.0
					item.addEventListener 'blur', a.1
				else
					# BLOCK OBJECT
					# reset state (TODO: detect?)
					#item.focused = 0
					# create and attach handler
					events.focus item.root, (root, v, e) !->
						# operate
						item.focused = v
						root.classList.toggle 'f', v
						# callback
						f o, v, e if f
					# done
					return true
			# }}}
			click: (item, f, o) !-> # {{{
				if item instanceof HTMLElement
					# DOM NODE
					# detach already attached
					if a = (e = getEvents item).click
						e.click = null
						item.removeEventListener 'click', a
					# check
					return if not f
					# create and attach handler
					o = item if arguments.length < 3
					item.addEventListener 'click', e.click = (e) !->
						e.preventDefault! # cancel activation behavior
						f o, e
				else
					# BLOCK OBJECT
					# create and attach handler
					events.click item.root, (root, e) ->>
						# check
						if item.locked
							return false
						# probe callback and
						# execute specific behaviour
						switch await f o, null
						case 1
							# LOCK-COMPLETE-UNLOCK
							# event is handled exclusively
							e.stopImmediatePropagation!
							# operate
							item.setLocked 2
							if await f o, e
								# complete
								item.setLocked 0 if item.locked == 2
						# done
						return true
			# }}}
			mmove: (item, f, o) !-> # {{{
				if item instanceof HTMLElement
					# DOM NODE
					# detach already attached
					if a = (e = getEvents item).mmove
						e.mmove = null
						item.removeEventListener 'pointermove', a
					# check
					return if not F
					# create and attach handler
					o = item if arguments.length < 3
					item.addEventListener 'pointermove', e.mmove = (e) !->
						if e.pointerType == 'mouse'
							e.preventDefault!
							f o, e
				else
					# BLOCK OBJECT
					# create and attach handler
					events.mmove item.root, (root, e) ->>
						# check
						if item.locked
							return false
						# probe callback and
						# execute specific behaviour
						switch await f o, e
						case 1
							# event is handled exclusively
							e.stopImmediatePropagation!
						# done
						return true
			# }}}
			detach: (block) !-> # {{{
				# extract
				if e = eventMap.get block
					# detach all
					for a of e when e[a]
						# detach already attached node
						events[a] block.root
						e[a] = 0# node detached
			# }}}
		}
	# }}}
	Object.assign blocks, { # {{{
		### PRIMITIVES (CSR constructors)
		group: do -> # {{{
			Block = (name, sup) !->
				# {{{
				@name   = name
				@super  = sup
				@blocks = []
				@config = sup.config
				@data   = null # sup.state[name]
				@level  = 0
				# }}}
			Block.prototype =
				init: !-> # {{{
					# order blocks by thier priority level (ascending)
					@blocks.sort (a, b) ->
						return if a.level < b.level
							then -1
							else if a.level == b.level
								then 0
								else 1
					# iterate
					for block in @blocks
						# each master block has a group property,
						# which must be set with the group object
						block.group  = @
						block.charge = @charge block
						# initialization of the group is all or nothing,
						# synchroneous operation, where each master obtains
						# access to the supervisor instance
						block.init @super
					# set data shortcut
					@data = @super.state[@name]
				# }}}
				sync: (block) !-> # {{{
					# synchronize all blocks in this group,
					# excluding specified block (initiator)
					for a in @blocks when a != block
						a.sync!
				# }}}
				charge: (block) -> !~> # {{{
					@sync block
					@super.charge block.level
				# }}}
			return Block
		# }}}
		resizer: do -> # TODO {{{
			Slave = (master, node) !->
				# {{{
				@parent   = master
				@node     = node
				@blocks   = null
				@factor   = 1
				@emitter  = null
				@handler  = null
				# }}}
			Master = (selector, blocks) !->
				# {{{
				@slaves = s = []
				# initialize
				# locate slave nodes
				n = [...(document.querySelectorAll selector)]
				# iterate
				for a in n
					# create a slave
					s[*] = b = new Slave @, a
					# set blocks
					b.blocks = c = []
					for d in blocks
						# lookup block parents
						e = d.root
						while e and e != a and (n.indexOf e) == -1
							e = e.parentNode
						# add
						c[*] = d if e == a
					# set handlers
					b.handler = e = @handler b
					for d in c when d.resizer
						d.resizer.onChange = e
				# }}}
			Master.prototype =
				handler: (s) -> (e) -> # {{{
					# check
					if s.factor > e or s.emitter == @block
						# lower factor or higher self,
						# update state and styles
						s.factor = e
						c = '--w3-factor'
						if e == 1
							s.node.style.removeProperty c
							s.emitter = null
						else
							s.node.style.setProperty c, e
							s.emitter = @block
					else
						# higher another, use minimal
						e = s.factor
					# done
					return e
				# }}}
			return Master
		# }}}
		grid: do -> # {{{
			Block = (o) !->
				# {{{
				# base
				@root    = o.root
				@rootBox = o.root.firstChild
				@cfg     = o.cfg or null
				# controls
				# ...
				# state
				@hovered = 0
				@focused = 0
				@locked  = 1
				# traps
				# ...
				# handlers
				#e = {hover:0}
				#e = Object.assign e, o.event if o.event
				#events.attach @, e
				# }}}
			Block.prototype =
				init: !-> # {{{
				# }}}
			return w3ui.factory 'grid', Block
		# }}}
		# TODO: refactor
		# TODO: scroller
		button: do -> # {{{
			Block = (root, o) !->
				# {{{
				# base
				@root    = root
				@cfg     = o.cfg or null
				@label   = w3ui.queryChild root, '.label'
				# state
				@rect    = null # DOMRect
				@hovered = 0
				@focused = 0
				@locked  = 1 # 0=unlocked, 1=locked, 2=deactivated
				###
				events.attach @, o.event
				# }}}
			Block.prototype =
				lock: (v = 1) !-> # {{{
					if @locked != v
						switch v
						case 2
							# deactivate (always from unlocked)
							@root.classList.add 'w'
							@root.disabled = true
							@locked = 2
						case 1
							# lock
							if @locked
								@root.classList.remove 'w'
							else
								@root.disabled = true
							@root.classList.remove 'v'
							@locked = 1
						default
							# unlock
							if @locked == 2
								@root.classList.remove 'w'
							else
								@root.classList.add 'v'
							@root.disabled = false
							@locked = 0
				# }}}
			return (o = {}) ->
				# assemble
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
				# prepare events
				e = {hover:0,focus:0}
				o.event = if o.event
					then Object.assign e, o.event
					else e
				# construct
				a = new Block a, o
				# unlock if not locked explicitly
				#a.lock 0 if not o.locked
				# done
				return a
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
			return (o = {}) -> # {{{
				# create a container
				a = document.createElement 'div'
				a.className = 'w3-select'+((o.name and ' '+o.name) or '')
				a.innerHTML = if o.hasOwnProperty 'svg'
					then o.svg
					else template
				# create a select
				b = document.createElement 'select'
				a.appendChild b
				# create block
				return new Block a, b
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
			return (o = {}) -> # {{{
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
		# }}}
	}
	# }}}
	Object.assign w3ui, {
		blocks: Object.freeze blocks
		events: Object.freeze events
		### COMPOUND VIEWS (CSR/SSR factories)
		gridlist: do -> # {{{
			# HELPERS {{{
			t1 = w3ui.template !-> # {{{
				/*
				*/
			# }}}
			t2 = w3ui.template !-> # {{{
				/*
				*/
			# }}}
			/***
			refresher = (block) !-> # {{{
				e = jQuery document.body
				e.on 'removed_from_cart', (e, frags) !->
					# prepare
					frags = frags['div.widget_shopping_cart_content']
					cart  = block.group.config.cart
					items = block.items
					# iterate
					for a,b of cart when b.count
						# search item in the fragments
						if (frags.indexOf 'data-product_id="'+a+'"') == -1
							# zap
							b.count = 0
							# search product in view
							e = -1
							while ++e < block.count
								if items[e].data.id == a
									items[e].refresh!
				###
			# }}}
				@intersect = (e) ~>> # {{{
					# fixed rows
					# {{{
					a = @block.config.layout
					if (c = @block.rows) or (c = a.1) == a.3
						# update
						if (a = @layout).1 != c
							@block.root.style.setProperty '--rows', (a.1 = c)
							a.0 and @block.setCount (a.0 * c)
						# done
						return true
					# }}}
					# dynamic rows
					# check locked
					if @dot.pending or not e
						console.log 'intersect skip'
						return true
					# prepare
					e = e.0.intersectionRatio
					o = @layout
					c = o.1
					b = a.3
					a = a.1
					# get scrollable container (aka viewport)
					if not (w = v = @i_opt.root)
						w = window
						v = document.documentElement
					# get viewport, row and dot heights
					h = v.clientHeight
					y = (@gaps.1 + @sizes.1) * @factor
					z = (@sizes.2 * @factor)
					# determine scroll parking point (dot offset),
					# which must be smaller than threshold trigger
					x = z * (1 - @i_opt.threshold.1 - 0.01) .|. 0
					# handle finite scroll
					# {{{
					if b
						# ...
						return true
					# }}}
					# handle infinite scroll
					# {{{
					# fill the viewport (extend scroll height)
					b = v.scrollHeight
					if e and b < h + z
						# determine exact minimum
						e  = Math.ceil ((b - c*y - z) / y)
						c += e
						b += y*e
						# update
						@block.root.style.setProperty '--rows', (o.1 = c)
						if o.0 and @block.setCount (o.0 * c) and @ready.pending
							@ready.resolve!
						# adjust scroll position
						@s_opt.0 = v.scrollTop
						@s_opt.1.top = b - h - x
						@s_opt.2.top = b - h - z
						# wait repositions (should be cancelled)
						await (@dot = w3ui.promise -1)
						@observer.1.disconnect!
						@observer.1.observe @block.dot
						# done
						return true
					# adjust the viewport
					while e
						# determine scroll options and
						# set scroll (after increment)
						@s_opt.1.top = b - h - x
						@s_opt.2.top = b - h - z
						if e > 0
							w.scrollTo @s_opt.1
						else if @s_opt.0 == -2
							w.scrollTo @s_opt.2
						# determine decrement's trigger point
						i = @s_opt.1.top - y - @pads.2
						# wait triggered
						if not (e = await (@dot = w3ui.promise i))
							break
						# check
						if e == 1
							# increment,
							# TODO: uncontrolled?
							c += 1
							b += y
						else
							# decrement,
							# determine intensity value
							i = 1 + (i - v.scrollTop) / y
							e = -(i .|. 0)
							console.log 'decrement', e
							# apply intensity
							c += e
							b += y*e
							# apply limits
							while c < a or b < h + z
								c += 1
								b += y
								i -= 1
								e  = 0 # sneaky escape (after update)
							# check exhausted
							if c == o.1
								console.log 'decrement exhausted'
								break
							# check last decrement
							if e and b - y < h + z and b - z > h + v.scrollTop
								e = 0
							# apply scroll adjustment (dot start)
							if (i - (i .|. 0))*y < (z - x + 1)
								if e
									console.log 'scroll alignment'
									@s_opt.0 = -2
								else
									console.log 'scroll alignment last'
									w.scrollTo @s_opt.2
						# update
						@block.root.style.setProperty '--rows', (o.1 = c)
						if o.0 and @block.setCount (o.0 * c) and @ready.pending
							@ready.resolve!
						# continue..
					# }}}
					# done
					return true
				# }}}
				@scroll = (e) ~>> # {{{
					# check intersection locked (upper limit determined)
					if not (a = @dot.pending)
						console.log 'scroll skip'
						return true
					# increase intensity
					if @intense.pending
						@intense.pending += 1
						return false
					# skip first scroll (programmatic)
					c = @s_opt.2.top
					d = @s_opt.1.top
					if (b = @s_opt.0) < 0
						console.log 'first scroll skip'
						@s_opt.0 = if ~b
							then c
							else d
						return false
					# get scrollable container (aka viewport)
					e = @i_opt.root or document.documentElement
					i = if e.scrollTop > b
						then 60  # increase
						else 100 # decrease
					# throttle (lock and accumulate)
					while (await (@intense = w3ui.delay i, 1)) > 1
						true
					# get current position
					e = e.scrollTop
					# check changed
					if (Math.abs (e - b)) < 0.2
						console.log 'small scroll skip'
						return true
					# save position
					@s_opt.0 = e
					# reposition?
					console.log 'reposition?', e, b, c, d
					if b > c + 1 and e < b and e > c - 1
						# exit (dot start)
						@s_opt.0 = -2
						a = window if not (a = @i_opt.root)
						a.scrollTo @s_opt.2
						console.log 'exit', @s_opt.2.top
						return true
					if b < d - 1 and e > b and e > c
						# enter (dot trigger)
						@s_opt.0 = -1
						a = window if not (a = @i_opt.root)
						a.scrollTo @s_opt.1
						console.log 'enter', @s_opt.1.top
						return true
					# increment?
					if e > d
						# reset and resolve positive
						console.log 'increment'
						@s_opt.0 = -1
						@dot.resolve 1
						return true
					# cancellation?
					if a < 0
						# negative upper limit means decrement is not possible
						# reset and cancel scroll observations
						console.log 'cancelled'
						@s_opt.0 = -1
						@dot.resolve 0
						return true
					# decrement?
					if e < a
						# resolve negative
						@dot.resolve -1
					# done
					return true
				# }}}
			/***/
			# }}}
			Resizer = (block) !->
				# {{{
				@block     = block
				@rootCS    = null
				@rootBoxCS = null
				###
				# static layout
				# proper size adjustments require recognition of
				# all the available space which excludes pads and gaps..
				# to be initialized..
				@ppb  = 0       # PPB unit size
				@pads = [       # container paddings
					0,0,          # left+right,top+bottom
					0             # bottom
				]
				@gaps = [0,0]   # grid gaps between [columns,rows]
				@size = [       # item dimensions in PPBs
					0,0,          # width,height
					0,0           # same, plus horizontal,vertical gap
				]
				###
				# dynamic layout
				@factor = 1             # current size factor (0-1)
				@obs    = null          # ResizeObserver
				@ready  = w3ui.promise! # properly resized?
				# }}}
				@resize = w3ui.debounce (e) ~> # {{{
					###
					# prepare
					# check parameter
					if e
						# observed event,
						# get width of the grid
						w = e.0.contentRect.width
					else
						# forced call,
						# determine width of the grid
						w = @block.root.clientWidth - @pads.0
					###
					# determine columns count and size factor
					# to estimate columns that fit into available width,
					# call helper with normal size factor
					[a,b] = @getColsAndWidth w, 1
					# compare available and taken widths
					# to determine proper size factor
					b = if b > w
						then w / b # reduced
						else 1     # normal
					###
					# update size factor
					# check responsibility
					if @block.onResize
						# supervisor control,
						# call back with desired factor and
						# check the response is even lower
						if (c = @block.onResize b) < b
							# re-calculate column count
							[a,b] = @getColsAndWidth w, c
					else
						# self control,
						# check factor changed enough (>0.5%)
						c = Math.abs (@factor - b)
						if c and (b == 1 or c > 0.005)
							# update
							c = @block.root.style
							if (@factor = b) < 1
								c.setProperty '--w3-factor', b
							else
								c.removeProperty '--w3-factor'
					###
					# update layout (columns only) and complete
					@block.setLayout a
					return true
					###
				, 300, 10
				# }}}
			Resizer.prototype =
				init: !-> # {{{
					# check
					@finit! if @obs
					# prepare
					# get and set container styles
					@rootCS = s0 = getComputedStyle @block.root
					@rootBoxCS = s1 = getComputedStyle @block.rootBox
					###
					# determine unit size
					@ppb = ppb = parseInt (s0.getPropertyValue '--w3-ppb')
					# determine container paddings,
					# computed values are absolute and
					# will be converted to relative ppbs
					a    = @pads
					b    = 'getPropertyValue'
					a.0  = (parseFloat (s0[b] 'padding-left')) / ppb
					a.0 += (parseFloat (s0[b] 'padding-right')) / ppb
					a.1  = (parseFloat (s0[b] 'padding-top')) / ppb
					a.2  = (parseFloat (s0[b] 'padding-bottom')) / ppb
					a.1 += a.2
					# determine grid gaps (set in ppbs)
					a   = @gaps
					a.0 = parseFloat (s0[b] '--col-gap')
					a.1 = parseFloat (s0[b] '--row-gap')
					# determine item dimensions
					c = @block.cfg
					if c.mode
						c = c.lines
						d = 'line'
					else
						c = c.cards
						d = 'card'
					a   = @size
					a.0 = c.0 or parseInt (s0[b] '--'+d+'-cols')
					a.1 = c.1 or parseInt (s0[b] '--'+d+'-rows')
					a.2 = a.0 + @gaps.0
					a.3 = a.1 + @gaps.1
					# resize is asynchroneous operation,
					# so first, set minimal grid layout first
					a = @block.layout
					b = @block.cfg
					a.0 = b.cols.0
					a.1 = b.rows.0
					# create observer and feed it with root node,
					# this makes first resize inevitable but not forced
					@obs = new ResizeObserver @resize
					@obs.observe @block.root
				# }}}
				finit: !-> # {{{
					# destroy observer
					@obs.disconnect!
					@obs = null
					# reset state
					@ready = w3ui.promise!
				# }}}
				getColsAndWidth: (w, e) -> # {{{
					# prepare
					e = @ppb * e
					# check display mode and
					# determine ideal column count and width taken
					if @block.cfg.mode
						# LINES
						# obviously, a single column and
						# maximal (specified) width of the line
						a = 1
						b = e * @size.0
					else
						# CARDS
						# check layout
						a = @block.cfg.cols
						if a.0 == a.1 or not a.1
							# fixed
							a = a.0
							b = e*(a * @size.0 + (a - 1) * @gaps.0)
						else
							# dynamic
							c = a.0
							a = a.1
							while (b = e*(a * @size.0 + (a - 1) * @gaps.0)) > w and a > c
								--a
					# done
					return [a,b]
				# }}}
				refresh: ->> # {{{
					# update layout
					await @resize! # columns
					await @intersect! # rows
					# done
					return true
				# }}}
			Block = (o) !->
				# {{{
				@root    = o.root
				@rootBox = o.root.firstChild
				@item    = o.item or blocks.grid
				@cfg     = w3ui.assign o.cfg, {
					# grid container
					# display mode: 0=cards (vertical), 1=lines (horizontal)
					mode: 0
					# dynamic layout: [min,max] 0=auto
					cols: [1,4]
					rows: [2,0]
					# item grid
					# static layout: [width,height]
					# in ppbs numbers (1*ppb == 1*[--w3-size]px),
					# 0=auto default (set in style file)
					cards: [0,0]
					lines: [0,0]
					# records
					# ordering tag and variant (0=asc, 1=desc, -1=none)
					order: ['default',-1]
					# should all the empty cells of the grid,
					# at the last or at the first page,
					# be filled with items from the opposite side?
					wraparound: 1
				}
				# controls
				@items    = null
				@resizer  = null
				@scroller = null
				# state
				@layout = [     # grid container
					0,0,          # columns,rows
					0             # items displayed columns*rows
				]
				@total  = -1    # total items available -1=undetermined
				@range  = [     # shared with loader
					0,   # primary offset (first record index)
					0,0, # forward range: offset,count
					0,0  # backward range
				]
				@bufA   = [] # forward buffer
				@bufB   = [] # backward buffer
				@offset = [  # buffer offsets
					0, # primary range offset (for update check)
					0, # current buffer offset (center point)
					0  # buffer is valid
				]
				@charged = 0
				@hovered = 0
				@focused = 0
				@locked  = 1
				# traps
				@onChange = null  # state change callback
				@onResize = null  # supervisor callback
				# handlers
				# attach
				e = {hover:0,focus:0}
				e = Object.assign e, o.event if o.event
				events.attach @, e
				# }}}
			Block.prototype =
				init: !-> # {{{
					# initialize
					# check and set display mode class
					a = 'cards'
					b = 'lines'
					c = a
					if @cfg.mode
						a = b
						b = c
					c = @root.classList
					if not c.contains a
						c.add a
					if c.contains b
						c.remove b
					# zap previous contents
					a = @rootBox
					while a.firstChild
						a.removeChild a.lastChild
					# initialize resizer
					if @resizer
						@resizer.finit!
					else
						@resizer = new Resizer @
					@resizer.init!
					# initialize range
					@total = -1
					@setRange 0
				# }}}
				setRange: (o, gaps) -> # {{{
					# prepare
					a = @range
					c = @cfg.limit
					# operate
					if not ~@total
						# the total is not determined yet,
						# external loader will determine proper range,
						# set desired offset, limits and special size value
						a.0 = o
						a.2 = a.4 = c
						a.1 = a.3 = -1 # request total
						###
					else if gaps
						# buffer replenishment required,
						# shift offsets to fill the gaps
						a.0 = o
						if (b = @bufA.length) < c
							if (a.1 = o + b) >= @total
								a.1 = a.1 - @total
							a.2 = c - b
						else
							a.1 = a.2 = 0
						if (b = @bufB.length) < c
							if (a.3 = o - 1 - b) < 0
								a.3 = a.3 + @total
							a.4 = c - b
						else
							a.3 = a.4 = 0
						###
					else
						# default range (@total > c + c)
						a.0 = a.1 = o
						a.2 = a.4 = c
						a.3 = if o
							then o - 1
							else @total - 1
						###
					# done
					return true
				# }}}
				setLayout: (cols, rows = 0) -> # {{{
					# prepare
					layout = @layout
					items  = @items
					rows   = layout.1 if not rows
					count  = cols * rows
					# check changed
					debugger
					if layout.0 == cols and layout.1 == rows
						return false
					# check direction
					if count > layout.2
						# INCREASE
						# {{{
						# show more items
						a = layout.2 - 1
						while ++a < count
							if a < items.length
								# reveal attached
								items[a].root.classList.add 'v'
							else
								# create and attach new item
								items[a] = @item {
									className: 'item'
								}
								# DOM assembly required
								@rootBox.appendChild items[a].root
						/***
						# update buffer offsets
						# determine initial shift size and direction
						o = @offset
						c = c - 1
						if (d = o.0 - o.1) >= 0
							d = d - @total if d > @cfg.limit
						else
							d = d + @total if d < -@cfg.limit
						# operate
						while ++c < count
							# TODO: fix
							# determine item's location in the buffer
							i = c + d
							if d >= 0
								# forward buffer
								b = @bufA[i]
							else if i >= 0
								# last page is not aligned with the total and
								# wrap around option may prescribe to display
								# records from the first page, blanks otherwise
								b = if @config.wrapAround
									then @bufA[i]
									else null
							else
								# backward buffer
								i = -i - 1
								b = @bufB[i]
							# set content (may be empty)
							a[c].set b
							a[c].root.classList.add 'v'
						/***/
						# }}}
					else if count < layout.2
						# DECREASE
						# hide redundant (dont destroy)
						a = layout.2 + 1
						while --a > count
							items[a].root.classList.remove 'v'
					# update values
					a = @block.root.style
					if layout.0 != cols
						a.setProperty '--cols', (layout.0 = cols)
					if layout.1 != rows
						a.setProperty '--rows', (layout.1 = rows)
					@layout.2 = count
					# callback
					@onChange @, 'layout' if @onChange
					# done
					return true
				# }}}
				setItem: (record) -> # {{{
					# prepare
					if not (o = @offset).2
						return false
					o = @offset
					A = @bufA
					B = @bufB
					# determine where to store this record
					if i < @range.2
						# store forward
						i = A.length
						A[i] = record
						# determine display offset
						i = if (o = o.0 - o.1) >= 0
							then i - o
							else i - @group.config.total - o
						# update item if it's displayed
						if i >= 0 and i < @count
							@items[i].set record
					else
						# store backward
						i = @bufB.length
						@bufB[i] = record
						# determine display offset
						i = if (o = o.1 - o.0) > 0
							then i - o
							else i - @group.config.total - o
						# update item if it's displayed
						if i < 0 and i + @count >= 0
							@items[-i - 1].set record
					# done
					return true
				# }}}
				setBuffer: -> # {{{
					# prepare
					A = @bufA
					B = @bufB
					R = @range
					a = A.length
					b = B.length
					c = @group.config.total
					d = @page
					o = @offset.0
					O = @offset.1
					# determine offset deviation
					if (i = o - O) > 0 and c - i < i
						i = i - c # swap to backward
					else if i < 0 and c + i < -i
						i = c + i # swap to forward
					# check out of range
					if (Math.abs i) > d + d - 1
						@clearBuffer!
						return 2
					# determine steady limit
					d = d .>>>. 1
					# check steady
					if i == 0 or (i > 0 and d - i > 0)
						# forward {{{
						# update items
						j = -1
						while ++j < @count
							if i < a
								@items[j].set A[i++]
							else
								@items[j].set!
						# }}}
						return 0
					if i < 0 and d + i >= 0
						# backward {{{
						# update items
						j = -1
						k = -i - 1
						while ++j < @count
							if k >= 0 and b - k > 0
								@items[j].set B[k]
							else if k < 0 and a + k > 0
								# option: the count of displayed items may not align
								# with the total count, so, the last page may show
								# records from forward buffer
								if @config.wrapAround
									@items[j].set A[-k - 1]
								else
									@items[j].set!
							else
								@items[j].set!
							--k
						# }}}
						return 0
					# check partial penetration
					if i > 0 and a - i > 0
						# forward {{{
						# [v|v|v|v]
						#   [v|v|v|x]
						# avoid creation of sparse array
						j = b
						while j < i
							B[j++] = null
						# rotate buffer forward
						j = i
						k = 0
						while k < b and j < @page
							B[j++] = B[k++]
						B.length = j
						j = i - 1
						k = 0
						while ~j
							B[j--] = A[k++]
						#j = -1
						#k = i
						while k < a
							A[++j] = A[k++]
						A.length = k = j + 1
						# update items (last to first)
						j = @count
						while j
							if --j < k
								@items[j].set A[j]
							else
								@items[j].set!
						# update range
						@setRange o, true
						# }}}
						return 1
					if i < 0 and b + i > 0
						# backward {{{
						#   [v|v|v|v]
						# [x|v|v|v]
						# avoid creation of sparse array
						i = -i
						j = a
						while j < i
							A[j++] = null
						# rotate buffer backward
						j = i
						k = 0
						while k < a and j < @page
							A[j++] = A[k++]
						A.length = j
						j = i - 1
						k = 0
						while ~j
							A[j--] = B[k++]
						#j = -1
						#k = i
						while k < b
							B[++j] = B[k++]
						B.length = j + 1
						# update items display (first to last)
						j = -1
						k = A.length
						while ++j < @count
							if j < k
								@items[j].set A[j]
							else
								@items[j].set!
						# update range
						@setRange o, true
						# }}}
						return -1
					# buffer penetrated (wasn't filled enough)
					@clearBuffer!
					return -2
				# }}}
				clearBuffer: !-> # {{{
					# set new range
					@setRange @offset.0
					# clear records
					@bufA.length = @bufB.length = 0
					# clear items
					i = @count
					while i
						@items[--i].set!
					# done
				# }}}
			return w3ui.factory 'gridlist', Block
		# }}}
		section: do -> # TODO: htab {{{
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
		# TODO: table
		### SUPERVISORS
		catalog: do -> # {{{
			configGroups = [ # {{{
				'locale'  # interface texts
				'routes'  # {id:route} navigation
				'order'   # order tags to use for ordering
				'currency'# [symbol,decimal_sep,thousand_sep,decimal_cnt]
				'cart'    # shopping cart
				'price'   # price range [min,max]
				'total'   # total records count
			]
			# }}}
			stateGroups = [ # {{{
				'lang'    # [primary,lang2,..]
				'route'   # [menu-id,navigation-id]
				'range'   # [offset,limit,o1,o2,o3,o4]
				'order'   # [tag,variant]
				'category'# [id-1..N],[..],..
				'price'   # [min,max]
			]
			# }}}
			Visor = (o) !->
				# {{{
				# create object shape
				@root    = o.root
				@brand   = o.brand or 'w3ui'
				@console = w3ui.console.new @brand, o.debug
				@slave   = o.s
				@master  = o.m
				@fetch   = httpFetch.create {
					baseUrl: o.apiURL
					mounted: true
					notNull: true
					method: 'POST'
				}
				@stream  = httpFetch.create {
					baseUrl: o.apiURL
					mounted: true
					notNull: true
					method: 'POST'
					timeout: 0
					parseResponse: 'stream'
				}
				@blocks  = []
				@groups  = Object.create null
				@state   = new w3ui.metaconstruct stateGroups
				@config  = if o.config
					then w3ui.assign o.config, configGroups
					else null
				#@resizer = null ???
				###
				@counter = 0    # total cycles (active)
				@lock    = null # charge promise
				@level   = 0    # charge level
				@dirty   = -1   # charge state
				@req     = null # stream request promise
				@view    = null # stream reciver
				@steady  = null # loop promise
				# }}}
			Visor.prototype =
				loop: ->> # {{{
					# check already started
					if @counter
						return false
					# prepare
					console = @console
					blocks  = @blocks
					@steady = w3ui.promise!
					console.log 'loop started'
					# loop forever
					while ++@counter
						# lock {{{
						# checks
						# - dirty -1: programmatic charges made by routine itself,
						#   are not throttled - as fast as possible
						# - dirty 0: charge by the user
						# - dirty 1: a guard against excessive charges triggered,
						#   multiple user actions are throttled input.
						@lock = if @dirty
							then w3ui.delay ((~@dirty and 400) or 0)
							else w3ui.promise 1
						# wait for the charge
						if not await @lock
							continue
						# set clean
						@dirty = 0
						# to accept the charge,
						# call masters back (in reversed order)
						a = blocks.length
						while ~--a
							if (b = blocks[a]).accept and not b.accept @level
								@dirty = -1 # programmatic restart
								break
						# restart or skip zero level
						if @dirty or not @level
							continue
						# lock down lower levels
						for b in blocks when b.level < @level and not b.locked
							b.locked = @level
							b.rootBox.classList.remove 'v'
							b.lock @level if b.lock
						# }}}
						# charge {{{
						# skip a moment
						await w3ui.delay 0
						if @dirty
							continue
						# initiate state request
						res  = await (@req = @stream @state)
						@req = null
						# check
						if res instanceof Error
							# cancelled, restart loop
							if res.id == 4
								continue
							# fatal
							console.error 'stream failed: '+res.message
							console.debug res
							break
						# }}}
						# sync and unlock {{{
						# set total records
						if (@config.total = await res.readInt!) == null
							console.error 'stream failed'
							res.cancel!
							break
						# call masters back
						for b in blocks
							# synchronize
							b.sync!
							# unlock
							if b.locked
								b.locked = 0
								b.rootBox.classList.add 'v'
								b.lock 0 if b.lock
						# reset
						@level = 0
						# }}}
						# discharge {{{
						# check the receiver
						if not @view
							res.cancel!
							continue
						# discharge
						@view.setItem null # hint
						while not @dirty and a = await res.readJSON!
							# check
							if a instanceof Error
								# fatal
								console.error 'stream failed: '+a.message
								console.debug a
								res.cancel!
								break
							# set
							if @view.setItem a
								# skip
								a = null
								res.cancel!
								break
						# exit fatal
						break if a
						# }}}
					# complete
					@counter = 0
					@steady.resolve!
					console.log 'loop finished'
					return true
				# }}}
				charge: (block) !-> # {{{
					# level up
					if block.level > @level
						@level = block.level
					# operate
					if @lock.pending
						# expected release (clear) or
						# timeout restart (dirty)
						@lock.resolve (@lock.pending == 1)
					else
						# unexpected, activate dirty timeout and
						# terminate fetcher
						@dirty = 1
						@req.cancel! if @req
				# }}}
				stop: -> # {{{
					# check
					if not @counter
						return false
					# interrupt loop
					@lock.resolve! if @lock
					@req.cancel! if @req
					# reset
					@dirty = @counter = -1
					@lock  = @req = null
					# complete
					return @steady
				# }}}
			return (o, autostart = true) ->>
				# CONSTRUCT
				sup     = new Visor o
				root    = sup.root
				brand   = sup.brand
				master  = sup.master
				console = sup.console
				blocks  = sup.blocks
				groups  = sup.groups
				time    = window.performance.now!
				await w3ui.delay 0
				console.log 'new supervisor'
				# INITIALIZE
				# create master blocks {{{
				for a of master
					# search DOM nodes
					b = root.querySelectorAll '.'+brand+'.'+a
					if not (c = b.length)
						continue
					# iterate found
					b = Array.from b
					d = -1
					while ++d < c
						# construct
						blocks[*] = e = new master[a] b[d]
						# determine view
						sup.view = e if e.view
				# check
				if not blocks.length
					console.error 'no blocks found'
					return null
				# sort by priority level (ascending)
				blocks.sort (a, b) ->
					return if a.level < b.level
						then -1
						else if a.level == b.level
							then 0
							else 1
				# }}}
				# create block groups {{{
				# each group represents a state block
				for b in blocks when ~(stateGroups.indexOf a = b.group)
					# create
					if not (c = groups[a])
						groups[a] = c = new w3ui.blocks.group a, @
					# add block
					c.blocks.push b
				# }}}
				await w3ui.delay 0
				console.log 'initializing..'
				# set configuration {{{
				# check wasnt determined (CSR init)
				if not @config
					# fetch from remote
					if (a = await fetch state) instanceof Error
						console.error 'failed to fetch configuration'
						console.debug a
						return null
					# set
					@config = w3ui.assign a, configGroups
				# }}}
				# set state {{{
				try
					# initialize groups in proper order,
					# blocks will inject state values
					for a in stateGroups when groups[a]
						groups[a].init!
					# sync blocks together
					for a in stateGroups when groups[a]
						await groups[a].sync!
				catch e
					console.error a+' group failed'
					console.debug e
					return null
				# set roots constructed
				for a in blocks when a.root
					a.root.classList.add 'v'
				# }}}
				#@onLoad @ if @onLoad
				#@resizer = newResizer '.'+BRAND+'-resizer', blocks
				# COMPLETE
				await w3ui.delay 0
				time = (window.performance.now! - time) .|. 0
				console.log 'ready ('+time+'ms)'
				sup.loop! if autostart # nowait
				return sup
		# }}}
	}
	return Object.freeze w3ui
###
