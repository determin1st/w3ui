"use strict"
w3ui = null
w3ui = do ->
	# TODO: state change prox
	# TODO: destiny operator
	# check requirements
	consoleLog = do -> # {{{
		style1 = 'font-weight:bold;color:palegreen'
		style2 = 'color:orangered;font-size:140%'
		style3 = 'font-size:140%'
		return (msg, noError) !->
			msg = '%cw3ui: %c'+msg
			if noError
				console.log msg, style1, style3
			else
				console.log msg, style1, style2
	# }}}
	# {{{
	api = [
		typeof fetch
		typeof Proxy
		typeof WeakMap
	]
	if api.includes 'undefined'
		consoleLog 'missing requirements'
		return null
	# }}}
	# internals
	# data {{{
	# determine w3ui runtime type:
	# - when loaded as a module, no w3ui variable is defined
	# - whel loaded from html, w3ui will present
	isModular = typeof w3ui == 'undefined'
	# create module load/unload mutex
	mutex = do ->
		return new Promise (resolve) !->
			resolve null
	# }}}
	loader = (m) -> (list) ->> # {{{
		# load each module
		for a in list
			# check already there
			if b = m[a]
				await b
				continue
			# check globals (easy deal)
			if b = window[a]
				m[a] = b
				continue
			# try loading
			if not (await m.load a)
				# fail
				return false
		# complete
		return true
	# }}}
	modules = do -> # {{{
		# create initial object shape
		# static dependencies (none)
		m = !->
		# set methods
		m.prototype = {
			load: (name) -> # {{{
				# calm
				# check already there
				if m[name]
					return m[name]
				# determine proper path
				# modules should follow some rules,
				# so the path is relatively restricted..
				# these restrictions dont provide
				# any protection against wrong input
				a = if isModular
					then './'+name+'.js'
					else './modules/'+name+'.js'
				# use mutex
				#  another restriction is one-by-one loading,
				#  this may be slower but ensures correct dependency order
				#  modules are "tough enough" (packed with features),
				#  so there is no much sense in their grouping..
				#  the monolith approach here, makes more sense and
				#  simplifies implementation - this feature
				#  should not be considered in terms of w3ui.
				# immediate promise setting
				#  enables certain code to wait
				#  until all of it's dependencies loaded
				return m[name] = mutex := mutex.then ->>
					try
						# import is relatively dynamic (bound to path)
						x = await ``import(a)``
						# check it's a Module
						if typeof x != 'object'
							consoleLog 'unexpected import result'
							return null
						# check it's have a default export
						if not (x = x.default)
							consoleLog 'incorrect import, no default'
							return null
						# wait for asynchronous constructor completion,
						# the result here, is allowed to be null (if module fails)
						# the re-load may be done after the unload
						x = await x
						# set a new module,
						# the modules are two kinds:
						# - internal, a module which has all of it's
						#   codebase inside w3ui modules/ and,
						#   is made in terms of w3ui project
						# - external, has it's own codebase, separate
						#   manual and a helper inside modules/ which
						#   that it's code is interoperable with w3ui
						#   it usally will be propagated to globals
						m[name] = x
						# propagate to globals
						if x.isGlobal
							window[name] = x
						# done
					catch x
						# fail
						consoleLog 'failed to load "'+name+'": '+x.message
						x = null
					# finish
					return x
			# }}}
			unload: (name) -> # {{{
				# aggressive
				return mutex := mutex.then ->
					# check loaded (no promise waiting here)
					if not m[name]
						return false
					# invoke module unloader (chained)
					if f = m[name].unload
						return mutex.then -> f!
					# dismount (also from globals)
					m[name] = null
					window[name] = null if window[name]
					return true
			# }}}
		}
		# create an instance (singleton)
		m = new m!
		# bind loader
		loader := loader m
		# complete
		return m
	# }}}
	# externals
	api = # {{{
		log: consoleLog
		load: loader
		timeout: do -> # {{{
			# helpers
			tick = (promise, ms, callback) -> !-> # {{{
				# invoke and check the result
				if callback and callback!
					# continue
					# re-create a timer
					promise.timer = setTimeout (tick promise, ms, callback), ms
				else
					# finish
					promise.cancel!
			# }}}
			cancel = (promise) -> !-> # {{{
				# stop timer
				if promise.timer
					clearTimeout promise.timer
				# resolve
				promise.timer   = 0
				promise.pending = false
				promise.resolve!
			# }}}
			# main
			return (ms, callback) ->
				# create a Promise and
				# extract its resolver
				r = null
				p = new Promise (resolve) !->
					r := resolve
				# extend standard object
				p.timer   = setTimeout (tick p, ms, callback), ms
				p.pending = true
				p.cancel  = cancel p
				p.resolve = r
				# done
				return p
		# }}}
		heredoc: (f) -> # {{{
			# check argument
			if not (typeof f == 'function')
				return ''
			# get function's text and
			# extract the comment
			f = f.toString!
			a = f.indexOf '/*'
			b = f.lastIndexOf '*/'
			return f.substring a + 2, b - 1 .trim!
		# }}}
		createElement: do -> # {{{
			temp = document.createElement 'template'
			return (html) ->
				temp.innerHTML = html
				return temp.content.firstChild
		# }}}
		state: do -> # {{{
			# helps to determine state changes
			return null
			/***
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
			/***/
		# }}}
	# }}}
	query = (s) -> # {{{
		return s
	# }}}
	# singleton
	return window.w3ui = new Proxy query, {
		get: (q, k) -> # {{{
			# SYNC RESULT
			# check special property
			switch k
			case 'then'
				# stop knocking here,
				# we are not a promise anymore
				return null
			case 'unload'
				# not exposed
				return null
			# check method/interface
			if api[k]
				return api[k]
			# check module
			if modules[k]
				return modules[k]
			# ASYNC RESULT
			# try auto-loading a module
			return modules.load k
		# }}}
		set: (q, k, v) -> # {{{
			# check special
			switch k
			case 'load', 'unload'
				return true
			# run module operations
			# unload
			if not v
				module.unload k
				return true
			# replacement
			if module[k]
				module.unload k
			# set user-defined module (trust)
			modules[k] = v
			# done
			return true
		# }}}
	}
###
# vim: ts=2 sw=2 sts=2 fdm=marker:
