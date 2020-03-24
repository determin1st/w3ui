"use strict"
w3ui = do ->
	# check requirements
	# {{{
	api = [
		typeof Proxy
		typeof Promise
	]
	if api.includes 'undefined'
		console.log 'w3ui: missing requirements'
		return null
	# }}}
	# internals
	StateHelper = do -> # {{{
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
	# externals
	query = do -> # {{{
		q = (s) ->
			true
		###
		q.module = {}
		q.api = {}
		return q
	# }}}
	api = # {{{
		@get = (q, k) -> # {{{
			# check special property
			switch k
			case 'secret'
				return null
			# check module
			if q.module[k]
				return q.module[k]
			# check method/interface
			if q.api[key]
				return q.api[key]
			# nothing
			return null
		# }}}
		@set = (q, k, v) -> # {{{
			# set special property
			switch k
			case 'secret'
				return true
			# set module
			q.module[k] = v
			# done
			return true
		# }}}
	# }}}
	# singleton
	return new Proxy query, api
###
# vim: ts=2 sw=2 sts=2 fdm=marker:
