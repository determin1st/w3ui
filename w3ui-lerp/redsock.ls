"use strict"
redsock = do ->
	/* TODO {{{
	*
	* CSS property group concept
	* FLIP tech: emulate DOM node position/size change with transforms
	* delay option
	* conditional jumps (onStart + reposition)
	* null tweens
	* standard eases: bounce, elastic, spring
	* custom eases: split, step, bezier, zoom
	* mutation/resize observer?
	*
	/* INSERTION sort {{{
	if (c = d.length) > 2
		# start from the second position,
		# splitting the array into left and right sections
		i = 1
		while i < c
			# get first element
			# from the right section
			a = d[i]
			# determine last position of the left section
			j = i - 1
			# shift all elements of the left section
			# to the right until the insert position found
			while j >= 0 and d[j] > a
				d[j + 1] = d[j]
				--j
			# insert and advance
			d[j + 1] = a
			++i
	/* }}} */
	/* }}} */
	TICKER = do -> # {{{
		# {{{
		InitData =
			id:       0
			queue:    []
			temp:     []
			index:    0
			size:     0
			min:      100
		LerpData =
			id:       0
			time:     0
			step:     0
			minStep:  17
			maxStep:  0
			pool:     new WeakSet!
			qLerp:    []
			qSync:    []
			qTmp:     []
			nLerp:    0
			nSync:    0
			iSync:    0
		# }}}
		initializer = (deadline) !-> # {{{
			# prepare
			{queue, temp, index, size} = d = InitData
			# initialize
			if index < size
				while index < size
					if (j = index + d.min) < size
						# chunks
						--index
						while ++index < j
							temp[index] = queue[index].init -1
						# check deadline
						if deadline and deadline.timeRemaining! == 0
							break
					else
						# remainder
						--index
						while ++index < size
							temp[index] = queue[index].init -1
				# continue later
				if deadline
					d.index = index
					d.id    = window.requestIdleCallback initializer
					return
			# synchronize animation targets
			while --index >= 0
				queue[index].initTargets!
			# cleanup and terminate
			queue.length = temp.length = 0
			d.id = d.size = d.index = 0
		# }}}
		interpolator = (timestamp) !-> # {{{
			# prepare
			{qLerp, qSync, qTmp, nLerp:n, step:s} = d = LerpData
			##
			# INTERPOLATE
			# iterate master-animations
			i = -1
			m = -1
			while ++i < n
				# advance position
				qLerp[i].move s
				# check sync deferred
				if d.iSync
					d.iSync = 0
					qTmp[++m] = qLerp[i]
			##
			# SYNC
			# iterate until all synchronized
			while k = d.nSync
				# prepare
				i = j = k
				# FLS tech (may inflict a reflow)
				# iterate sync queue
				while --i >= 0
					qSync[i].syncFirst!
				while ++i < j
					qSync[i].syncLast!
				while --i >= 0
					if qSync[i].syncSteady!
						qSync[--k] = qSync[i]
				# check the result
				if k < j
					# WARNING: initial state is unclear
					# IFR tech (will force a reflow)
					i = j
					k = k - 1
					while --i > k
						qSync[i].syncInvert!
					while ++i < j
						qSync[i].syncFirst!
					while ++k < j
						qSync[k].syncReady!
				# reset counter
				d.nSync = 0
				# iterate master-animations
				i = -1
				j = -1
				while ++i <= m
					# update at current position
					qTmp[i].update!
					# check sync deferred
					if d.iSync
						# another sync cycle is required and may produce more reflows
						# this depends on animation nesting level and CSS configuration
						d.iSync = 0
						qTmp[++j] = qTmp[i]
				# reset counter
				m = j
			##
			# RENDER
			# iterate master-animations
			i = -1
			j = -1
			while ++i < n
				# check animation is ready (iterpolated) and
				# call the renderer..
				if (k = qLerp[i]).ready
					k.render!
				# check animation is still active and
				# store it to the next frame sequence
				if k.active
					qLerp[++j] = k
				else
					# finish rendering and
					# remove animation from the interpolator
					k.initTargets!
					d.pool.delete k
			##
			# COMPLETE
			# check the result
			if (d.nLerp = j + 1) != 0
				# determine step size
				if (s = Math.round (timestamp - d.time)) < d.minStep
					# throttle
					s = d.minStep
				else if d.maxStep and s > d.maxStep
					# choke
					s = d.maxStep
				# continue
				d.step = s
				d.time = timestamp
				d.id   = window.requestAnimationFrame interpolator
			else
				# terminate
				d.step = d.id = 0
		# }}}
		return
			init: !-> # {{{
				# prepare
				d = InitData
				# add to the queue
				d.queue[d.size] = @
				++d.size
				# start the worker
				if d.id == 0
					d.id = window.requestIdleCallback initializer
			# }}}
			start: !-> # {{{
				# prepare
				d = LerpData
				# check started
				if not d.pool.has @
					# add to the queue
					d.pool.add @
					d.qLerp[d.nLerp] = @
					++d.nLerp
					# start iterpolation
					if d.id == 0
						d.time = window.performance.now!
						d.id   = window.requestAnimationFrame interpolator
			# }}}
			sync: !-> # {{{
				# prepare
				d = LerpData
				# add to the queue
				d.qSync[d.nSync] = @
				++d.nSync
				++d.iSync
			# }}}
			completeInit: !-> # {{{
				# abort current callback request
				if i = InitData.id
					window.cancelIdleCallback i
				# force complete
				initializer!
			# }}}
			cleanup: !-> # {{{
				if (d = LerpData).id == 0
					d.qLerp.length = d.qSync.length = d.qTmp.length = 0
			# }}}
			currentFPS: # {{{
				configurable: false
				get: ->
					return if LerpData.id == 0
						then 0
						else 1000 / LerpData.step
			# }}}
			minFPS: # {{{
				configurable: false
				get: ->
					return if LerpData.maxStep
						then 1000 / LerpData.maxStep
						else 0
				set: (v) !->
					# check
					if (v = parseInt v) < 0 or v > 60
						console.error 'redsock:ticker:minFPS: incorrect'
						return
					# set
					LerpData.maxStep = if v == 0
						then 0
						else Math.round (1000 / v)
			# }}}
	# }}}
	EASE = do -> # {{{
		# prepare
		variant = ['in' 'out' 'in-out' 'out-in']
		pool = {linear: null}
		# define ease generator
		gen =
			power: # {{{
				variant: true
				pool: [1.5, 2, 3, 4, 5, 6]
				default: 2
				func: (variant, n) ->
					switch variant
					| 'in' =>
						f = (x) ->
							return x**n
					| 'out' =>
						f = (x) ->
							return 1 - (1 - x)**n
					| 'in-out' =>
						f = (x) ->
							return if x < 0.5
								then ((2 * x)**n) / 2
								else 1 - ((2 * (1 - x))**n) / 2
					| 'out-in' =>
						c1 = Math.pow 0.5, 1/n
						c2 = 2 * c1
						c3 = 0.5 / Math.pow 0.5, n
						f = (x) ->
							return if x < 0.5
								then 0.5 - (c1 - c2*x)**n
								else 0.5 + c3*(x - 0.5)**n
					return f
			# }}}
			exp: # {{{
				variant: true
				func: (variant) ->
					switch variant
					| 'in' =>
						f = (p) ->
							return Math.exp 10*(p - 1)
					| 'out' =>
						f = (p) ->
							return 1 - Math.exp (-10 * p)
					| 'in-out' =>
						f = (p) ->
							p = p * 2
							return if p < 1
								then 0.5 * (Math.exp 10*(p - 1))
								else 1 - 0.5 * (Math.exp 10*(1 - p))
					| 'out-in' =>
						c1 = 1 / (2 - 2 / Math.exp 10)
						f = (p) ->
							if p < 0.5
								return c1 - c1*(Math.exp (-10 * 2*p))
							return 1 - c1 + c1*(Math.exp 10*(2*p - 2))
					return f
			# }}}
			circ: # {{{
				variant: true
				func: (variant) ->
					switch variant
					| 'in' =>
						f = (p) ->
							return 1 - Math.sqrt (1 - p * p)
					| 'out' =>
						f = (p) ->
							p = p - 1
							return Math.sqrt (1 - p * p)
					| 'in-out' =>
						f = (p) ->
							if (p = p * 2) < 1
								return 0.5 * (1 - Math.sqrt (1 - p * p))
							p = p - 2
							return 0.5 * (1 + Math.sqrt (1 - p * p))
					| 'out-in' =>
						f = (p) ->
							if p < 0.5
								p = p - 0.5
								return Math.sqrt (0.25 - p * p)
							p = 2*p - 1
							return 1 - 0.5*Math.sqrt (1 - p * p)
					return f
			# }}}
			sine: # {{{
				variant: true
				func: (variant) ->
					c1 = Math.PI / 2
					c2 = Math.PI * 2
					switch variant
					| 'in' =>
						f = (p) ->
							return 1 - Math.cos (p * c1)
					| 'out' =>
						f = (p) ->
							return Math.sin (p * c1)
					| 'in-out' =>
						f = (p) ->
							return 0.5 - 0.5 * Math.cos (p * Math.PI)
					| 'out-in' =>
						f = (p) ->
							if p < 0.5
								return 0.5 * Math.sin (p * Math.PI)
							return 1 - 0.5 * Math.sin (p * Math.PI)
					return f
			# }}}
			back: # {{{
				variant: true
				pool: [1, 1.4, 1.7, 2]
				default: 1
				func: (variant, amp) ->
					switch variant
					| 'in' =>
						c1 = amp + 1
						f = (x) ->
							return x * x * (c1*x - amp)
					| 'out' =>
						c1 = amp + 1
						f = (x) ->
							x = x - 1
							return x * x * (c1*x + amp) + 1
					| 'in-out' =>
						c1 = amp * 1.525
						c2 = c1 + 1
						f = (x) ->
							if (x = x * 2) < 1
								return 0.5 * x * x * (c2*x - c1)
							x = x - 2
							return 0.5 * x * x * (c2*x + c1) + 1
					| 'out-in' =>
						c1 = amp * 1.525 / 2
						c2 = c1 + 0.5
						f = (x) ->
							if x <= 0.5
								x = 2*x - 1
								return x * x * (c2*x + c1) + 0.5
							x = 2*x - 1
							return x * x * (c2*x - c1) + 0.5
					return f
			# }}}
			bounce: # {{{
				variant: true
				pool: [0, 0, 0]
				default: 1
				/***
					_wrap("Bounce",
						_create("BounceOut", function(p) {
							if (p < 1 / 2.75) {
								return 7.5625 * p * p;
							} else if (p < 2 / 2.75) {
								return 7.5625 * (p -= 1.5 / 2.75) * p + 0.75;
							} else if (p < 2.5 / 2.75) {
								return 7.5625 * (p -= 2.25 / 2.75) * p + 0.9375;
							}
							return 7.5625 * (p -= 2.625 / 2.75) * p + 0.984375;
						}),
						_create("BounceIn", function(p) {
						}),
						_create("BounceInOut", function(p) {
							var invert = (p < 0.5);
							if (invert) {
								p = 1 - (p * 2);
							} else {
								p = (p * 2) - 1;
							}
							if (p < 1 / 2.75) {
								p = 7.5625 * p * p;
							} else if (p < 2 / 2.75) {
								p = 7.5625 * (p -= 1.5 / 2.75) * p + 0.75;
							} else if (p < 2.5 / 2.75) {
								p = 7.5625 * (p -= 2.25 / 2.75) * p + 0.9375;
							} else {
								p = 7.5625 * (p -= 2.625 / 2.75) * p + 0.984375;
							}
							return invert ? (1 - p) * 0.5 : p * 0.5 + 0.5;
						})
					);
				/***/
				func: (variant, x) ->
					switch variant
					| 'in' =>
						f = (p) ->
							p = 1 - p
							if p < 1 / 2.75
								return 1 - (7.5625 * p * p)
							else if p < 2 / 2.75
								p = p - 1.5 / 2.75
								return 1 - (7.5625 * p * p + 0.75)
							else if p < 2.5 / 2.75
								p = p - 2.25 / 2.75
								return 1 - (7.5625 * p * p + 0.9375)
							p = p - 2.625 / 2.75
							return 1 - (7.5625 * p * p + 0.984375)
					| 'out' =>
						f = (p) ->
							return p
					| 'in-out' =>
						f = (p) ->
							return p
					| 'out-in' =>
						f = (p) ->
							return p
					return f
			# }}}
			elastic: # {{{
				variant: true
				pool: []
				###
				/***
					_createElastic = function(n, f, def) {
						var C = _class("easing." + n, function(amplitude, period) {
								this._p1 = (amplitude >= 1) ? amplitude : 1; //note: if amplitude is < 1, we simply adjust the period for a more natural feel. Otherwise the math doesn't work right and the curve starts at 1.
								this._p2 = (period || def) / (amplitude < 1 ? amplitude : 1);
								this._p3 = this._p2 / _2PI * (Math.asin(1 / this._p1) || 0);
								this._p2 = _2PI / this._p2; //precalculate to optimize
							}, true),
							p = C.prototype = new Ease();
						p.constructor = C;
						p.getRatio = f;
						p.config = function(amplitude, period) {
							return new C(amplitude, period);
						};
						return C;
					};
					_wrap("Elastic",
						_createElastic("ElasticOut", function(p) {
							return this._p1 * Math.pow(2, -10 * p) * Math.sin( (p - this._p3) * this._p2 ) + 1;
						}, 0.3),
						_createElastic("ElasticIn", function(p) {
							return -(this._p1 * Math.pow(2, 10 * (p -= 1)) * Math.sin( (p - this._p3) * this._p2 ));
						}, 0.3),
						_createElastic("ElasticInOut", function(p) {
							return ((p *= 2) < 1) ? -0.5 * (this._p1 * Math.pow(2, 10 * (p -= 1)) * Math.sin( (p - this._p3) * this._p2)) : this._p1 * Math.pow(2, -10 *(p -= 1)) * Math.sin( (p - this._p3) * this._p2 ) * 0.5 + 1;
						}, 0.45)
					);
				/***/
				func: (variant, x) ->
					switch variant
					| 'in' =>
						f = (p) ->
							return p
					| 'out' =>
						f = (p) ->
							return p
					| 'in-out' =>
						f = (p) ->
							return p
					| 'out-in' =>
						f = (p) ->
							return p
					return f
			# }}}
			step: # {{{
				func: (p) -> p
			# }}}
		# create input parsers
		parser = (name) -> # {{{
			# check
			if not name
				return null
			# extract from pool
			if pool.hasOwnProperty name
				return pool[name]
			# check ease type
			# CUSTOM: user specified parameters
			if (name.indexOf ' ') > 0
				return customParser name
			# FIXED: parameters are extracted from the pool
			# parse variant
			if (n = name.split '-').length < 2
				console.log 'redsock: ease variant is not specified "'+name+'"'
				return null
			# get it
			v = (n.slice 1).join '-'
			# check
			if (variant.indexOf v) < 0
				console.log 'redsock: incorrect ease variant "'+v+'"'
				return null
			# parse
			if not (n = n.0.match /([a-z]+)(\d*)/)
				console.log 'redsock: incorrect ease name "'+name+'"'
				return null
			# get name and parameter index
			[n, i] = n.slice 1
			# extract generator
			if not n or not (f = gen[n])
				if n != 'linear'
					console.log 'redsock: incorrect ease name "'+name+'"'
				return null
			# construct
			if f.pool
				# check index
				if not i or not (i = parseInt i)
					# check default index available
					if 'default' in f
						console.log 'redsock: ease parameter required "'+name+'"'
						return null
					# set default
					i = f.default
				else if i > f.pool.length
					console.log 'redsock: wrong ease parameter "'+name+'"'
					return null
				# call generator
				f = f.func v, f.pool[i - 1]
			else
				# call generator
				f = f.func v
			# store name
			f.keyword = name
			# store function
			pool[name] = f
			# done
			return f
		# }}}
		customParser = (name) -> # TODO {{{
			# extract name and parameter
			[n, i] = name.split ' '
			if not (n = name.split '-').length
				true
			# extract geneartor
			if not n or not gen.hasOwnProperty n
				console.log 'redsock: incorrect ease name "'+name+'"'
				return null
			# parse parameters
			if not (i = i.split ',')
				console.log 'redsock: incorrect ease parameters "'+name+'"'
				return null
			# call generator
			if not (f = gen[n] i)
				return null
			# store function
			f.keyword = name
			pool[name] = f
			return f
		# }}}
		parser.pool = pool
		parser.gen = gen
		# done
		return parser
	# }}}
	CSS = do -> # {{{
		TargetMap = new WeakMap!
		TweenMap = new !-> # {{{
			map =
				pixel: # {{{
					init: !->
						@v1    = parseFloat @first
						@v2    = parseFloat @last
						@delta = @v2 - @v1
					lerp: ->
						return (@v1 + @delta * @active.scale) + 'px'
				# }}}
				integer: # {{{
					init: !->
						@v1    = parseInt @first
						@v2    = parseInt @last
						@delta = @v2 - @v1
					lerp: ->
						return (@v1 + @delta * @active.scale) .|. 0
				# }}}
				float: # {{{
					init: !->
						@v1    = parseFloat @first
						@v2    = parseFloat @last
						@delta = @v2 - @v1
					lerp: ->
						return @v1 + @delta * @active.scale
				# }}}
				color: do -> # {{{
					# HotRod tech
					RGBAParse = do -> # {{{
						exp = /(\d+),\s*(\d+),\s*(\d+)(,\s*(\d*(\.\d+)?))?/
						return (v) ->
							# parse string
							v = v.match exp
							# cast parsed chunks into array
							return [
								parseInt v.1
								parseInt v.2
								parseInt v.3
								if v.5
									then parseFloat v.5
									else 1
							]
					# }}}
					init =
						!-> # RGB^2 {{{
							# parse values
							@v1 = c1 = RGBAParse @first
							@v2 = c2 = RGBAParse @last
							# prepare for RGB^2 blending
							c1.0 = c1.0 ** 2
							c1.1 = c1.1 ** 2
							c1.2 = c1.2 ** 2
							# set delta
							@delta = d = [
								c2.0 ** 2 - c1.0
								c2.1 ** 2 - c1.1
								c2.2 ** 2 - c1.2
								c2.3 - c1.3
							]
							# set interpolator
							@lerp = if (Math.abs d.3) < 0.001
								then lerp.0             # color only
								else if c2.3 < 0.001
									then lerp.4           # alpha only, visible => invisible
									else if c1.3 < 0.001
										then lerp.5         # alpha only, invisible => visible
										else lerp.1         # color and alpha
						# }}}
						!-> # RGB {{{
							# parse values
							@v1 = c1 = RGBAParse @first
							@v2 = c2 = RGBAParse @last
							# set delta
							@delta = d = [
								c2.0 - c1.0
								c2.1 - c1.1
								c2.2 - c1.2
								c2.3 - c1.3
							]
							# set interpolator
							@lerp = if (Math.abs d.3) < 0.001
								then lerp.2             # color only
								else if c2.3 < 0.001
									then lerp.4           # alpha only, visible => invisible
									else if c1.3 < 0.001
										then lerp.5         # alpha only, invisible => visible
										else lerp.3         # color and alpha
						# }}}
					lerp =
						-> # RGB^2 color {{{
							# prepare
							a = @v1
							b = @delta
							c = @active.scale
							# resolve
							return 'rgba('+
								((Math.sqrt (a.0 + b.0 * c)) .|. 0)+','+
								((Math.sqrt (a.1 + b.1 * c)) .|. 0)+','+
								((Math.sqrt (a.2 + b.2 * c)) .|. 0)+','+
								a.3+')'
						# }}}
						-> # RGB^2 color & alpha {{{
							# prepare
							a = @v1
							b = @delta
							c = @active.scale
							# set current
							return 'rgba('+
								((Math.sqrt (a.0 + b.0 * c)) .|. 0)+','+
								((Math.sqrt (a.1 + b.1 * c)) .|. 0)+','+
								((Math.sqrt (a.2 + b.2 * c)) .|. 0)+','+
								((a.3 + b.3 * c).toFixed 2)+')'
						# }}}
						-> # RGB color {{{
							# prepare
							a = @v1
							b = @delta
							c = @active.scale
							# set current
							return 'rgba('+
								((a.0 + b.0 * c) .|. 0)+','+
								((a.1 + b.1 * c) .|. 0)+','+
								((a.2 + b.2 * c) .|. 0)+','+
								a.3+')'
						# }}}
						-> # RGB color & alpha {{{
							# prepare
							a = @v1
							b = @delta
							c = @active.scale
							# set current
							return 'rgba('+
								((a.0 + b.0 * c) .|. 0)+','+
								((a.1 + b.1 * c) .|. 0)+','+
								((a.2 + b.2 * c) .|. 0)+','+
								((a.3 + b.3 * c).toFixed 2)+')'
						# }}}
						-> # Alpha only => invisible {{{
							# prepare
							a = @v1
							# set current
							return 'rgba('+a.0+','+a.1+','+a.2+','+
								((a.3 + @delta.3 * @active.scale).toFixed 2)+')'
						# }}}
						-> # Alpha only => visible {{{
							# prepare
							a = @v2
							# set current
							return 'rgba('+a.0+','+a.1+','+a.2+','+
								((@v1.3 + @delta.3 * @active.scale).toFixed 2)+')'
						# }}}
					return
						init: init.0
						lerp: lerp.0
						config: (enableRGB2) ->
							# get
							if arguments.length == 0
								return @init == init.0
							# set
							@init = if enableRGB2
								then init.0
								else init.1
							# done
							return true
				# }}}
				transforms: # {{{
					group: do ->
						Group = (me) !->
							# initialize group object
							@left   = null
							@right  = null
							@top    = null
							@bottom = null
							@width  = null
							@height = null
							# initialize tween data
							me.v1 = [
								0, 0,     # A(x,y)
								0, 0,     # B(x,y)
								0, 0,     # C(x,y)
								new DOMMatrix!
							]
							me.v2 = [
								0, 0,     # dA(x,y)
								0, 0,     # dB(x,y)
								0, 0,     # dC(x,y)
								new DOMMatrix!
								false     # flag for lerper to set origin
							]
						# done
						return Group
					init: (t) !->
						# prepare
						a = @v1
						b = @v2
						if @steady == 2
							# ...
							# static
							# ...
							true
						# TODO: optimize
						# compute reverse-transformation matrix
						m   = b.6
						c   = a.0*(b.4 - b.2) + a.2*(b.0 - b.4) + a.4*(b.2 - b.0)
						d   = b.0*(b.3 - b.5) + b.2*(b.5 - b.1) + b.4*(b.1 - b.3)
						m.c = c / d
						m.a = (a.2 - a.0 - m.c * (b.3 - b.1)) / (b.2 - b.0)
						m.e = a.0 - m.a * b.0 - m.c * b.3
						c   = a.1*(b.4 - b.2) + a.3*(b.0 - b.4) + a.5*(b.2 - b.0)
						d   = b.1*(b.4 - b.2) + b.3*(b.0 - b.4) + b.5*(b.2 - b.0)
						m.d = c / d
						m.b = (a.3 - a.1 - m.d * (b.3 - b.1)) / (b.2 - b.0)
						m.f = a.1 - m.b * b.0 - m.d * b.3
						# determine delta
						d   = a.6
						d.a = m.a - d.a
						d.b = m.b - d.b
						d.c = m.c - d.c
						d.d = m.d - d.d
						d.e = m.e - d.e
						d.f = m.f - d.f
						# set origin flag
						b.7 = true
					lerp: (s) !->
						# prepare
						a = @v1.6
						b = @v2
						c = @active.scale
						# set origin
						if b.7
							b.7 = false
							s.transformOrigin = (-b.0)+'px '+(-b.1)+'px'
						# set transformation
						b = b.6
						s.transform = 'matrix('+
							(b.a - c * a.a)+','+
							(b.b - c * a.b)+','+
							(b.c - c * a.c)+','+
							(b.d - c * a.d)+','+
							(b.e - c * a.e)+','+
							(b.f - c * a.f)+')'
				# }}}
			Tween = !->
				# controller data
				@active  = null   # animation store reference
				@steady  = 0      # 0:none 1:flat&static 2:rule&(dynamic|static)
				@group   = false  # tween type flag
				@name    = ''
				# projected data
				@first   = false
				@last    = null
				# iterpolated data and methods
				@v1      = null
				@v2      = null
				@delta   = null
				@init    = null
				@lerp    = null
			###
			Descriptor = (name, type) !->
				@name = name
				@{init, lerp, config, group, apply} = type
				@construct = (prop) ->
					# create base tween
					a = new Tween!
					# initialize
					a.init = @init
					a.lerp = @lerp
					if @group
						# set property group
						a.group = true
						a.name  = @name
						for b of a.last = new @group a
							prop[b] = a
					else
						# set individual property
						a.name = prop
					# done
					return a
			###
			# initialize singleton
			for a of map
				@[a] = new Descriptor a, map[a]
			# cleanup
			a = map = Descriptor = null
		# }}}
		PropMap = new !-> # {{{
			map =
				pixel: # {{{
					isDynamic: (v) -> not v.endsWith 'px'
					filter: (v) ->
						return if typeof v == 'number'
							then v+'px'
							else v
					list:
						'left'
						'right'
						'top'
						'bottom'
						'width'
						'height'
						'maxWidth'
						'minWidth'
						'maxHeight'
						'minHeight'
						'perspective'
						'flexBasis'
						'gridRowGap'
						'gridColumnGap'
						'columnGap'
						'columnRuleWidth'
						'borderTopWidth'
						'borderBottomWidth'
						'borderLeftWidth'
						'borderRightWidth'
						'borderTopLeftRadius'
						'borderTopRightRadius'
						'borderBottomLeftRadius'
						'borderBottomRightRadius'
						'marginTop'
						'marginBottom'
						'marginLeft'
						'marginRight'
						'paddingTop'
						'paddingBottom'
						'paddingLeft'
						'paddingRight'
						'outlineOffset'
						'outlineWidth'
						'fontSize'
						'lineHeight'
						'wordSpacing'
						'textIndent'
				# }}}
				integer: # {{{
					isDynamic: (v) -> false
					filter: (v) ->
						return if isNaN (v = parseInt v)
							then ''
							else v.toString!
					list:
						'zIndex'
						'order'
						'columnCount'
						'fontWeight'
				# }}}
				float: # {{{
					isDynamic: (v) -> false
					filter: (v) ->
						return if isNaN (v = parseFloat v)
							then ''
							else v
					list:
						'flexGrow'
						'flexShrink'
						'opacity'
						'fontSizeAdjust'
				# }}}
				color: # {{{
					isDynamic: (v) -> false
					filter: (v) -> v
					list:
						'color'
						'backgroundColor'
						'borderTopColor'
						'borderBottomColor'
						'borderLeftColor'
						'borderRightColor'
						'outlineColor'
						'columnRuleColor'
						'caretColor'
					# }}}
			###
			create = -> @type.construct @camel
			Descriptor = (tween, prop, camel, hyphen) !->
				@camel   = camel
				@hyphen  = hyphen
				@type    = tween
				@create  = create
				@{isDynamic, filter} = prop
			###
			# initialize singleton
			for a,b of map
				for c in b.list
					# convert property name to hyphen case
					# and create interned string
					d = {}
					d[(c.replace /([a-zA-Z])(?=[A-Z])/g, '$1-').toLowerCase!] = true
					d = Object.keys d .0
					# store
					@[c] = new Descriptor TweenMap[a], b, c, d
					@[d] = @[c] if c != d
		# }}}
		RuleMap = new !-> # {{{
			# constructors
			RuleValue = (value, flag) !-> # {{{
				@value   = value
				@dynamic = flag
			# }}}
			RuleSet = !-> # {{{
				@list = []
				@prop = new PropSet!
			# }}}
			Descriptor = (cssRule) !-> # {{{
				# prepare
				list = []
				prop = new PropSet!
				# iterate CSSStyleDeclaration (hyphen-cased names) and
				# collect animatable properties
				for a in (b = cssRule.style) when c = PropMap[a]
					# get the value (using camel case)
					a = c.camel
					d = b[a]
					# store it
					list[*] = a
					prop[a] = new RuleValue d, c.isDynamic d
				# check
				if list.length
					# determine selector specificity
					# this operation is simplified by class-based design and
					# for better match/lookup performance..
					a = cssRule.selectorText
					b = 100*((a.split '#').length - 1) + 10*((a.split '.').length - 1)
					# create monomorphic object shape
					@list     = list
					@prop     = prop
					@selector = a
					@weight   = b
			# }}}
			# initialize singleton
			# {{{
			@list = [] # Descriptors
			@data = {} # id => RuleSet
			@size = 0
			# }}}
			@init = (sheetFilter, selectFilter) !-> # {{{
				# reset data
				@list.length = 0
				@data = {}
				# collect StyleSheet objects
				# from document
				if sheetFilter
					# filter sheets
					# by title attribute
					b = []
					for a in document.styleSheets
						if sheetFilter.includes a.title
							b[*] = a
				else
					# get them all
					b = document.styleSheets
				# collect rules (CSSStyleRule objects)
				# from enabled StyleSheets
				c = []
				i = -1
				for a in b when not a.disabled
					try
						for a in a.cssRules when a.type == 1
							c[++i] = a
					catch
						console.warn 'redsock:css: failed to get stylesheet rules'
				# filter rule property sets
				# by inclusive class marker
				if selectFilter
					b = []
					i = -1
					for a in c
						if (a.selector.indexOf selectFilter) != -1
							b[++i] = a
					c = b
				# create rule property sets
				b = @list
				i = -1
				for a in c when (a = new Descriptor a).list
					b[++i] = a
				# sort by specificity
				b.sort (a, b) ->
					a = a.weight
					b = b.weight
					return if a == b
						then 0
						else if a < b
							then -1
							else 1
				# determine class identifier size
				# JS strings are UTF-16, so each character key will keep 16 rule bitflags
				@size := 1 + (b.length .>>>. 4)
			# }}}
			@match = (node) -> # {{{
				# prepare
				k = new Uint16Array @size
				{list, prop} = s = new RuleSet!
				# match rule selectors (ordered by specificity) and
				# create reduced property set
				for a,i in @list
					if node.matches a.selector
						# determine position of the bit block and
						# the value to apply to the identifier
						b = i .>>>. 4
						i = 1 .<<. (i - (b .<<. 4))
						# apply it
						k[b] = k[b] .|. i
						# merge property set
						b = a.prop
						for i in a.list
							# add new property name to the list and
							# set the value (overwrite)
							list[*] = i if not prop[i]
							prop[i] = b[i]
				# create combination key
				k = String.fromCharCode.apply null, k
				# store the result
				@data[k] = s
				# done
				return k
			# }}}
			@diff = (v1, v2) -> # {{{
				# prepare
				# create result holder
				{list, prop} = o = new RuleSet!
				# get property sets
				v1 = @data[v1]
				v2 = @data[v2]
				# extract lists and props
				l1 = v1.list
				l2 = v2.list
				v1 = v1.prop
				v2 = v2.prop
				# merge differences
				for a in l2 when not v1[a] or v1[a] != v2[a]
					# unique or non-equal
					list[*] = a
					prop[a] = v2[a]
				for a in l1 when not v2[a]
					# unique only (always dynamic)
					list[*] = a
					prop[a] = new RuleValue '', true
				# done
				return o
			# }}}
			@option = (o) -> # {{{
				# create property set
				{list, prop} = option = new RuleSet!
				# parse options and
				# add individual properties
				for a,b of o when c = PropMap[a]
					# get camel name and filter value
					a = c.camel
					b = c.filter b
					# store it
					list[*] = a
					prop[a] = new RuleValue b, c.isDynamic b
				# done
				return if list.length == 0
					then null
					else option
			# }}}
		# }}}
		###
		PropSet = do -> # {{{
			# collect camel property names map
			m = {}
			for a of PropMap
				m[PropMap[a].camel] = true
			# create precompiled constructor expression
			f = '(function() {'
			for a of m
				f += 'this.'+a+' = null;'
			# cleanup
			m = a = null
			# done
			return f = eval f + '})'
		# }}}
		ClassTween = !-> # {{{
			@active  = null # animation tween reference
			@list    = null # ordered name chunks
			@name    = null # class name
		# }}}
		ClassOption = !-> # {{{
			@add    = null
			@remove = null
			@toggle = null
		# }}}
		ClassOption.prototype = # {{{
			resolve: (list) !->
				# copy name chunks
				a = list.slice!
				# apply option
				if @add
					for b in @add when not a.includes b
						a[*] = b
				if @remove
					for b in @remove when (c = a.indexOf b) != -1
						a[c] = false
				if @toggle
					for b in @toggle
						if (c = a.indexOf b) == -1
							a[*] = b
						else
							a[c] = false
				# filter removed and
				# sort the result
				return a.filter Boolean .sort!
		# }}}
		TweenData  = !-> # {{{
			@captive = null   # previous tween (overwritten)
			@first   = null   # initial value
			@last    = null   # final/projected value
			@dynamic = false
		# }}}
		AnimationStore = (animation) !-> # {{{
			# initialize monomorphic object shape
			# set animation data
			@ref = animation
			@scale = 0
			# set class tween data
			o = animation.options
			if o.className
				@clas = a = new TweenData!
				a.dynamic = o.className
			else
				@clas = null
			# set combined property data (inline + class)
			@prop = new PropSet!
			# set inline/individual properties
			if o.css
				@list = o.css.list
				c = o.css.prop
				for a in @list
					@prop[a]  = b = new TweenData!
					b.last    = c[a].value
					b.dynamic = c[a].dynamic
			else
				@list = null
		# }}}
		TargetTween = (target) !-> # {{{
			# target
			@target    = target         # DOM node
			@style     = null           # computed style reference
			# animation storage
			@tween     = []
			@complete  = []
			# class tween
			@name      = new ClassTween!# class name tween
			@id        = {}             # name => id
			@rule      = {}             # id1 => id2 => rules
			# property tweens
			@active    = []             # interpolated group/properties
			@list      = []             # inactive individual property list
			@prop      = new PropSet!   # property map
			# state flags
			@ready     = false
			@steady    = false
			@go        = false
		# }}}
		TargetTween.prototype = # {{{
			apply: (aTween) !->
				# prepare
				{active, list, prop} = @
				style = @target.style
				# apply class tween
				# {{{
				if c = aTween.clas
					# backup current
					c.first = (d = @name).list
					a = d.name
					# determine final
					if d.active
						b = c.last = c.dynamic.resolve d.list
					else
						b = c.last
					# capture
					c.captive = d.active
					d.active  = aTween
					# switch class
					d.list = b
					d.name = b = b.join ' '
					@target.setAttribute 'class', b
					# checkout identifier
					if not (c = @id)[b]
						c[b] = RuleMap.match @target
					# checkout applied rules (property set)
					a = c[a]
					b = c[b]
					c = @rule
					if not d = c[a]
						c[a] = {}
						d = c[a][b] = RuleMap.diff a, b
					else if not (d = c[a][b])
						d = c[a][b] = RuleMap.diff a, b
					###
					# apply class-based property tweens
					b = aTween.prop
					c = d.prop
					for a in d.list
						# get property data
						if e = b[a]
							# check final state determined,
							# which means that property is inline and
							# must be skipped
							continue if e.last
						else
							# class-based property data is grown lazily..
							# create new data cell in animation store
							e = b[a] = new TweenData!
						# get property tween
						if not (d = prop[a])
							# WARNING: initial property value is not determined
							# reset flag to enforce IFR tech and
							# create new individual property tween
							@ready  = false
							list[*] = prop[a] = d = PropMap[a].create!
						# backup initial inline-style
						e.first = style[a]
						# activate
						if d.group
							###
							# grouped property
							# check state
							if d.active != aTween
								if d.active
									# DIRTY
									# override previous controller
									# ...
									true
								else
									# CLEAN
									# activate this group
									active[*] = d
								# set controller
								d.active = aTween
								d.steady = 2
							# set projected/final value
							if (d.last[a] = c[a]).dynamic
								# apply relative value
								style[a] = c[a].value if e.first
								@steady  = false
								d.steady = 0
						else
							###
							# individual property
							# check state
							if d.active
								# DIRTY
								# override previous controller
								if d.active.ref.complete
									# dont override completed animation
									# simply clue first and last values
									d.first = d.last.value
								else
									# override (TODO: simultaneous start)
									e.captive = d.active
									d.first   = e.first
							else
								# CLEAN
								# activate this property
								active[*] = d
							# set controller
							d.active = aTween
							# set projected/final value
							if c[a].dynamic
								# relative value
								style[a] = c[a].value if e.first
								@steady  = false
							else
								# absolute value
								d.last   = c[a].value
								d.steady = 1
				# }}}
				# apply inline property tweens
				# {{{
				if aTween.list
					b = aTween.prop
					for a in aTween.list
						# prepare
						d = prop[a]
						e = b[a]
						# capture property tween
						if d.active != aTween
							# check already captured
							if d.active
								# backup initial
								e.first = d.first
								# clue together
								if d.active.ref.complete
									# borders
									d.first   = d.last
								else
									# overlap
									e.captive = d.active
									d.first   = d.lerp!
							else
								# backup current inline style
								e.first = style[a]
								# activate
								active[*] = d
							# capture
							d.active = aTween
							d.delta  = null
							# set final value
							if e.dynamic
								# relative
								d.last   = null
								style[a] = e.last
								@steady  = false
							else
								# absolute
								d.last = e.last
				# }}}
				# done
		# }}}
		return
			# configurators
			init: !-> # {{{
				RuleMap.init!
			# }}}
			cleanup: !-> # {{{
				TargetMap := new WeakMap!
			# }}}
			enableRGB2: # {{{
				configurable: false
				get: -> TweenMap.color.config!
				set: TweenMap.color.config
			# }}}
			# exports
			newOptionProp: RuleMap.option
			newOptionClass: (o) -> # {{{
				# check empty
				if not o
					return null
				# prepare storage
				o1 = []
				o2 = []
				o3 = []
				# parse parameter and
				# collect actions
				for a in (o.split ' ')
					switch a.0
					| '+' => o1[*] = a.substring 1
					| '-' => o2[*] = a.substring 1
					| '!' => o3[*] = a.substring 1
				# check the result
				if not o1.length and not o2.length and not o3.length
					return null
				# create and initialize option
				a = new ClassOption!
				a.add    = o1 if o1.length
				a.remove = o2 if o2.length
				a.toggle = o3 if o3.length
				# done
				return a
			# }}}
			createTargets: !-> # {{{
				# prepare
				@target = ta = []
				@tween  = tw = []
				# iterate DOM targets
				for t in @options.target
					# create target tween
					if not (a = TargetMap.get t)
						TargetMap.set t, (a = new TargetTween t)
					# create animation tween
					a.tween[*] = b = new AnimationStore @
					a.style = null
					# store
					ta[*] = a
					tw[*] = b
			# }}}
			initTargets: !-> # {{{
				for t in @target when not t.active.length
					# prepare
					{target, name, list, prop} = t
					###
					# initialize
					if not t.style
						# set computed style
						t.style = window.getComputedStyle target
						# reset property tween list
						list.length = 0
						# analyze bound animations
						for a in t.tween
							# create property tween groups (TODO)
							if true
								list[*] = TweenMap.transforms.construct prop
							# create individual property tweens
							if a.list
								for b in a.list when not prop[b]
									list[*] = prop[b] = PropMap[b].create!
						# analyze class attribute
						# set name
						name.list = (target.className.split ' ').sort!
						name.name = b = name.list.join ' '
						# set identifier
						a = t.id[name.name] = RuleMap.match target
						# iterate class rules
						for a in RuleMap.data[a].list
							if not prop[a]
								list[*] = prop[a] = PropMap[a].create!
						# iterate inline rules
						for a in target.style when b = PropMap[a]
							if not prop[b.camel]
								list[*] = prop[b.camel] = b.create prop
					###
					# update animation store
					for a in t.tween
						# invalidate progress
						a.scale = 0
						# resolve projected class
						if b = a.clas
							b.last = b.dynamic.resolve name.list
					###
					# update initial state of property tweens
					# prepare
					a = target.style
					b = RuleMap.data[t.id[t.name.name]].prop
					# iterate
					for prop in list
						# reset state
						prop.steady = 0
						prop.first  = false
						# get property/group name
						name = prop.name
						# check
						if prop.group
							# property group (TODO)
							# ...
							true
						else
							# individual property
							# checkout inline-style
							if a[name]
								if not PropMap[name].isDynamic a[name]
									prop.first = a[name]
							# checkout class-style
							else if b[name]
								if not b[name].dynamic
									prop.first = b[name].value
					###
					# reset target state
					t.ready  = false
					t.steady = false
				# reset master-animation state
				@started  = false
				@complete = false
				@position = 0
			# }}}
	# }}}
	ANIMATION = do -> # {{{
		Animation = (options, parent, index) !-> # {{{
			# create monomorphic object shape
			# set data
			@options  = options
			@queue    = false   # children/nested animations
			@duration = 0       # base timing (in milliseconds)
			@delay    = 0       # skip timing
			@position = 0       # absolute position
			@ease     = false   # position change factor
			@target   = false   # target tween storage
			@tween    = false   # animation tween storage
			@callback = false   # self-clone with user callbacks
			@api      = false   # object with bound public methods
			# state flags
			@started  = false   # passed onStart and synchronized with the DOM
			@active   = false   # updating position (ticking)
			@complete = false   # finished, no more updates
			@ready    = false   # ready for rendering
			# parent
			if @parent = parent
				# slave-animation
				# set master reference
				@proxy = if parent.parent
					then parent.proxy
					else parent
				# instant initialization
				@init index
			else
				# master-animation
				# set public api
				@proxy = new Proxy @, apiProxy
				# deferred initialization
				@deferInit!
		# }}}
		Animation.prototype = # {{{
			# internal
			init: do -> # {{{
				optionType = new !-> # {{{
					map =
						clone: # {{{
							Object: (v) ->
								# extract redsock animation object
								return if v = v.redsock
									then v
									else null
						# }}}
						target: # {{{
							Array: true
							loose: (v) ->
								# wrap DOM node into array
								return if not v instanceof Element
									then null
									else [v]
						# }}}
						duration: # {{{
							String: (v) ->
								# convert to number
								if isNaN (v = parseFloat v)
									return null
								# convert to milliseconds
								if (v = (1000 * v) .|. 0) < 1
									return null
								# done
								return v
							Number: (v) ->
								# convert to milliseconds
								if (v = (1000 * v) .|. 0) < 1
									return null
								# done
								return v
						# }}}
						delay: # {{{
							Number: (v) ->
								# convert to milliseconds
								if (v = (1000 * v) .|. 0) < 1
									return null
								# done
								return v
						# }}}
						position: # {{{
							String: true
							Number: (v) ->
								# absolute position,
								# convert to milliseconds
								return if v < 0
									then null
									else (1000 * v) .|. 0
						# }}}
						label: # {{{
							String: true
						# }}}
						ease: # {{{
							Function: true
							String: EASE
						# }}}
						className: # {{{
							String: CSS.newOptionClass
						# }}}
						css: # {{{
							Object: CSS.newOptionProp
						# }}}
						queue: # {{{
							Array: (v) ->
								# check empty
								if v.length == 0
									return null
								# create new array holder
								x = []
								# refine values
								for a in v
									# check type
									if (c = typeof a) == 'function'
										# wrap into callback
										x[*] = {onUpdate: a}
									else if c != 'object' or not a
										# unimplemented
										return null
									else if a.redsock
										# wrap redsock object
										x[*] = {clone: a}
									else
										x[*] = a
								# done
								return x
						# }}}
						positions: # {{{
							Array: true
							Number: (v) ->
								# STAGGER value
								# check in range 0..100%
								if v < 0 or v > 100
									return null
								# convert to string
								return '^'+v
						# }}}
						onStart: # {{{
							Function: true
						# }}}
						onUpdate: # {{{
							Function: true
						# }}}
						onComplete: # {{{
							Function: true
						# }}}
					Type = !->
						@Boolean  = false
						@Number   = false
						@String   = false
						@Function = false
						@Object   = false
						@Array    = false
						@loose    = false
					# initialize singleton
					for a of map
						@[a] = b = new Type!
						for c of map[a]
							b[c] = map[a][c]
					# cleanup
					map = Type = a = b = c = null
				# }}}
				Option = do -> # {{{
					# create precompiled constructor
					f = '(function() {'
					for a of optionType
						f += 'this.'+a+' = null;'
					return f = eval f + '})'
				# }}}
				Option.prototype = # {{{
					createMap: ->
						true
				# }}}
				optionList = # {{{
					'clone'
					'target'
					'duration'
					'delay'
					'position'
					'label'
					'ease'
					'className'
					'css'
					'queue'
					'positions'
					'onStart'
					'onUpdate'
					'onComplete'
				# }}}
				optionInherit = # {{{
					position: (parent, index) -> # {{{
						# check parent specified positions
						if a = parent.options.positions
							switch typeof a
							| 'string' =>
								return a
							| 'object' =>
								return a[index] if a[index] != null
						# nothing
						return null
					# }}}
					ease: (parent, index) -> # {{{
						return if parent = parent.options.ease
							then parent
							else false
					# }}}
				# }}}
				optionCloneable = do -> # {{{
					m =
						'target'
						'duration'
						'label'
						'ease'
						'className'
						'css'
						'queue'
						'positions'
						'onStart'
						'onUpdate'
						'onComplete'
					# construct
					o = new Option!
					for a of o
						o[a] = m.includes a
					# done
					return o
				# }}}
				Queue = (parent, list) !-> # {{{
					# parse list into the queue and
					# determine total duration
					q = []
					duration = 0
					for a,i in list
						# construct nested animation
						q[i] = a = new Animation a, parent, i
						# determine absolute position
						if a.options.position == null
							# not specified,
							# append to the end
							a.position = duration
							duration = duration + a.delay + a.duration
						else
							# specified
							# parse relative value
							if typeof (b = a.position) == 'string'
								switch b.0
								| '^' =>
									# STAGGERED offset (0-100%)
									# from the previous animation start
									if i == 0
										# first animation
										# does not have any shift
										b = 0
									else
										# determine the shift
										c = q[i - 1]
										b = (parseInt b.substring 1) / 100
										b = (c.position + b * (c.delay + c.duration)) .|. 0
								| '+' =>
									# POSITIVE offset (in seconds)
									# from current position
									b = duration + 1000 * (parseFloat b) .|. 0
								| '-' =>
									# NEGATIVE offset (in seconds)
									# from current position
									b = duration + 1000 * (parseFloat b) .|. 0
									b = 0 if b < 0
								| otherwise =>
									# LABELED offset
									# TODO
									b = 0
							# set position
							a.position = b
							# extend duration
							if (b = b + a.delay + a.duration) > duration
								duration = b
					# create monomorphic object shape
					@list     = q
					@duration = duration
					@start    = b = []
					@stop     = c = []
					@delta    = d = []
					# initialize
					if parent.options.duration != null
						# scale queue with parent's duration
						@scaleDuration (parent.duration - duration) / duration
					else
						# create interpolation points
						for a,i in q
							b[i] = a.position
							c[i] = b[i] + a.delay + a.duration
							d[i] = c[i] - b[i]
				# }}}
				Queue.prototype = # {{{
					scaleDuration: (s) !-> # {{{
						# prepare
						b = @start
						c = @stop
						d = @delta
						# deviate self
						@duration = @duration + (@duration * s .|. 0)
						# deviate children
						for a,i in @list
							# set values
							a.position = a.position + (a.position * s .|. 0)
							a.duration = a.duration + (a.duration * s .|. 0)
							a.delay    = a.delay + (a.delay * s .|. 0)
							# set interpolation point
							b[i] = a.position
							c[i] = b[i] + a.delay + a.duration
							d[i] = c[i] - b[i]
							# recurse
							a.queue.scaleDuration s if a.queue
					# }}}
				# }}}
				return (index) ->
					# get user-defined options and
					# create empty options object
					x = @options
					@options = o = new Option!
					# apply type filters
					# {{{
					# iterate ordered list
					for a in optionList
						if x.hasOwnProperty a
							# specified
							# get the value and determine its type
							b = x[a]
							c = typeof! b
							d = optionType[a]
							# apply option type filter
							if c = d[c]
								# strict
								b = c b if c != true
							else if b and c = d.loose
								# loose
								b = c b
							else
								# incorrect
								b = null
							# set filtered value
							if (o[a] = b) == null
								console.error 'redsock:option:'+a+': incorrect'
						else
							# not specified,
							# try to clone
							if optionCloneable[a] and o.clone and b = o.clone.options[a]
								o[a] = b
					# }}}
					# check instance type
					if index == -1
						# master-animation
						# bind public methods
						@api = new Api @, @proxy
					else
						# slave-animation
						# inherit options from parent
						for a of optionInherit when not o[a]
							o[a] = optionInherit[a] @parent, index
					# initialize animation
					# set standard
					@duration = o.duration if o.duration != null
					@delay    = o.delay    if o.delay    != null
					@position = o.position if o.position != null
					@ease     = o.ease     if o.ease     != null
					# set callbacks
					if o.onStart or o.onUpdate or o.onComplete
						# clone self
						@callback = a = ^^@
						# put user callbacks on cloned object
						# to enable them to:
						# + get animation properties through prototype chain
						# + use clone as a data storage
						a.onStart    = o.onStart
						a.onUpdate   = o.onUpdate
						a.onComplete = o.onComplete
					# set target tweens
					if o.target
						@createTargets!
					# set nested animations
					if o.queue
						# create queue
						@queue = q = new Queue @, o.queue
						# set duration
						if o.duration == null
							@duration = q.duration
						# get target tween storage
						if not (c = @target)
							c = @target = []
						# add unique targets
						for a in q.list when a.target
							for b in a.target when not c.includes b
								c[*] = b
					# done
					return x
			# }}}
			move: (s) !-> # {{{
				# advance position and
				# check the end reached
				if (@position += s) > @duration
					# complete
					@active   = false
					@complete = true
					@position = @duration
				# done
				@update!
			# }}}
			update: !-> # {{{
				# prepare
				q = @queue
				p = @position
				# update self
				# {{{
				if @started
					if @tween
						# prepare
						a = @target
						b = @tween
						c = b.length
						i = -1
						# update animation tweens
						if @complete
							# set complete
							while ++i < c
								d = a[i]
								d.go = true
								d.complete[d.complete.length] = b[i]
						else
							# set current
							# determine scale (relative position)
							d = p / @duration
							d = @ease d if @ease
							# iterate and set
							while ++i < c
								a[i].go = true
								b[i].scale = d
						# set master-animation flag
						if @parent
							@proxy.ready = true
						else
							@ready = true
					# trigger callbacks
					if c = @callback
						c.onUpdate and c.onUpdate!
						@complete and c.onComplete and c.onComplete!
				else
					# startup
					# trigger callback
					if (c = @callback) and c.onStart and not c.onStart!
						return
					# set flag
					@started = true
					# defer FLRS synchronization
					@deferSync! if @tween
					# re-activate queue
					if q
						for a in q.list
							a.active   = true
							a.started  = false
							a.complete = false
							a.position = 0
				# }}}
				# update queue
				# {{{
				if q
					# prepare
					{start:b, stop:c, delta:d} = q
					# iterate active
					for a,i in q.list when a.active
						# check started
						if a.started
							# check local position edge cases
							if b[i] > p
								if not a.complete
									# revert
									a.complete = true
									a.started  = false
									a.position = 0
									a.update!
							else if c[i] <= p
								if not a.complete
									# complete
									a.complete = true
									a.position = a.duration
									a.update!
							else
								# normal update
								a.complete = false
								a.position = p - b[i]
								a.update!
						else if b[i] <= p
							# apply first update to
							# trigger child startup
							a.update!
							# de-activate on failure
							if not a.started
								a.active = false
				# }}}
				# done
			# }}}
			render: !-> # {{{
				# master-animation
				# iterate and render all running targets
				for t in @target when t.go
					# prepare
					active   = t.active
					complete = t.complete
					style    = t.target.style
					# complete animations
					# {{{
					if k = complete.length
						# iterate completed animation stores
						i = -1
						while ++i < k
							# prepare
							c = complete[i]
							j = -1
							# re-assemble active property tweens
							for a in active
								if a.active == c
									# get property data
									e = c.prop
									# release interpolator
									if a.group
										# property group
										# apply final inline-style
										for b of d = a.group when d[b]
											style[b] = e[b].last
										# release captive
										# ...
										d = null
										# apply specific changes
										if not d
											if a.name == 'transforms'
												style.transform = null
												style.transformOrigin = null
									else
										# individual property
										# apply final inline-style
										b = e[a.name]
										style[a.name] = b.last
										# release captive
										while d = b.captive
											# invalidate
											b.captive = null
											# check
											if not d.ref.complete
												break
											# continue
											b = d.prop[a.name]
									# de-activate
									if a.active = d
										# skip if re-activated
										active[++j] = a
								else
									# skip
									active[++j] = a
							# done
							active.length = j + 1
						# done
						complete.length = 0
					# }}}
					# render tweens
					for a in active
						if a.group
							# property group
							a.lerp style
						else
							# individual property
							style[a.name] = a.lerp!
					# done
					t.go = false
				# done
				@ready = false
			# }}}
			# FLS tech
			syncFirst: !-> # {{{
				# prepare
				target = @target
				j = @tween.length
				i = -1
				# iterate own targets
				while ++i < j
					if not (t = target[i]).ready
						# update property tween's
						# initial state
						for a in t.list when not a.first
							if a.group
								# property group
								if a.name == 'transforms'
									# determine initial points and matrix
									b = a.v1
									c = t.target.getBoundingClientRect!
									b.0 = c.left
									b.1 = c.top
									b.2 = b.0 + c.width
									b.3 = b.1
									b.4 = b.2
									b.5 = b.1 + c.height
									b.6.setMatrixValue t.style.transform
								# done
								a.first = true
							else
								# individual property
								a.first = t.style[a.name]
						# done
						# set optimistic flags
						t.ready  = true
						t.steady = true
			# }}}
			syncLast: !-> # {{{
				# prepare
				{target, tween} = @
				j = tween.length
				i = -1
				# iterate own targets and apply tweens
				while ++i < j
					target[i].apply tween[i]
			# }}}
			syncSteady: -> # {{{
				# prepare
				invert = false
				target = @target
				j = @tween.length
				i = -1
				# iterate own targets
				while ++i < j
					# check final state
					# {{{
					if not (t = target[i]).steady
						# iterate active, steady and
						# determine projected/final state
						for a in t.active when not a.steady
							if a.group
								# for property group
								if a.name == 'transforms'
									# 3-points for 2d-transformations
									b = a.v2
									c = t.target.getBoundingClientRect!
									b.0 = c.left
									b.1 = c.top
									b.2 = b.0 + c.width
									b.3 = b.1
									b.4 = b.2
									b.5 = b.1 + c.height
							else
								# for individual property
								a.last = t.style[a.name]
							# done
							a.steady = 1
						# done
						t.steady = true
					# }}}
					# check initial state
					# {{{
					if t.ready
						for a in t.active when a.steady
							# initialize tween
							if a.group
								a.init t
							else
								a.init!
							# done
							a.steady = 0
					else
						# initial state is not determined
						# set flag to enable IFR tech for this target
						invert = true
					# }}}
				# done
				return invert
			# }}}
			# IFR tech
			syncInvert: !-> # {{{
				# prepare
				target = @target
				j = @tween.length
				i = -1
				# iterate own targets
				while ++i < j
					t = target[i]
					if not t.ready and t.steady
						# un-apply class tween
						# get initial tween
						a = t.name.active
						while b = a.clas.captive
							a = b
						# switch back
						t.target.setAttribute 'class', (a.clas.first.join ' ')
						# up-apply dynamic, class-based property tweens
						# with undetermined initial value
						b = t.target.style
						for a in t.active when not a.first
							b[a.name] = null # clear inline style for syncFirst
							a.delta   = null # invalidate for syncReady
						# set flags
						t.steady = false
						t.go = true
			# }}}
			syncReady: !-> # {{{
				# prepare
				target = @target
				j = @tween.length
				i = -1
				# iterate own targets
				while ++i < j
					t = target[i]
					if t.go
						# re-apply class tween
						t.target.setAttribute 'class', t.name.name
						# initialize inverted property tweens
						for a in t.active when not a.delta
							a.init!
						# set flags
						t.go = false
			# }}}
			# imports
			createTargets: CSS.createTargets
			initTargets: CSS.initTargets
			deferInit: TICKER.init
			deferStart: TICKER.start
			deferSync: TICKER.sync
		# }}}
		Api = do -> # {{{
			method =
				start: (me, proxy) -> -> # {{{
					# activate
					if not me.active
						me.active = true
						me.deferStart!
					# done
					return proxy
				# }}}
				stop: (me, proxy) -> -> # {{{
					# deactivate
					me.active = false
					# done
					return proxy
				# }}}
				cancel: (me, proxy) -> -> # {{{
					# done
					return proxy
				# }}}
				complete: (me, proxy) -> (noCallback) -> # {{{
					# done
					return proxy
				# }}}
				set: (me, proxy) -> (scale) -> # {{{
					# done
					return proxy
				# }}}
			# create precompiled constructor
			f = '(function(a,b) {'
			for a of method
				f += 'this.'+a+' = method.'+a+'(a,b);'
			return f = eval f + '})'
		# }}}
		apiProxy = do -> # {{{
			alias = # {{{
				play: 'start'
				pause: 'stop'
				revert: 'cancel'
				finish: 'complete'
				progress: 'set'
			# }}}
			return
				get: (me, k) -> # {{{
					# check instance initialized
					if not me.api
						TICKER.completeInit!
						console.log 'redsock: forced initialization'
					# property access
					switch k
					| 'active' =>
						# flags
						return me[k]
					| 'target' =>
						# DOM nodes
						return me.options.target
					| 'duration' =>
						# convert to seconds
						return me.duration / 1000
					| 'scale', 'progress' =>
						# relative position 0..100%
						return me.position / me.duration
					| 'ease' =>
						# extract ease method string
						return if me.ease
							then me.ease.keyword
							else 'linear'
					| 'redsock' =>
						# self-extraction
						return me
					# api method access
					if me.api[k]
						return me.api[k]
					if alias[k]
						return me.api[alias[k]]
					# default
					return me[k]
				# }}}
				set: (me, k, v) -> # {{{
					switch k
					| 'onStart', 'onUpdate', 'onComplete' =>
						# create monomorphic clone
						if not (c = me.callback)
							c = me.callback = ^^me
							c.onStart = false
							c.onUpdate = false
							c.onComplete = false
						# set callback
						c[k] = v
					# done
					return true
				# }}}
		# }}}
		return Animation
	# }}}
	return do ->
		me = (options) -> # {{{
			# check
			if (typeof! options) != 'Object'
				console.error 'redsock:options: incorrect type'
				return null
			# create master-animation
			# and return api-proxy
			return (new ANIMATION options).proxy
		# }}}
		me.init = !-> # {{{
			CSS.init!
		# }}}
		me.cleanup = !-> # {{{
			TICKER.cleanup!
			CSS.cleanup!
		# }}}
		# global options {{{
		# define
		Object.defineProperty me, 'FPS', TICKER.currentFPS
		Object.defineProperty me, 'minFPS', TICKER.minFPS
		Object.defineProperty me, 'enableRGB2', CSS.enableRGB2
		# set defaults
		me.minFPS = 10
		me.ease = EASE
		# }}}
		return Object.seal me

# vim: set noet ts=2 sw=2 sts=2 fdm=marker fenc=utf-8 ff=dos:
