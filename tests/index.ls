"use strict"
window.addEventListener 'load', !->>
	# TEST ENVIRONMENT SETUP
	# {{{
	###
	# load w3ui (dynamic module load)
	window.w3ui = await (await ``import('../modules/w3ui.js')``).default
	###
	# load dependencies
	await w3ui.httpFetch
	###
	# custom fetcher
	# determine current location
	isLocal = (window.location.href.indexOf 'local') != -1
	# determine remote server's base url
	server = if isLocal
		then 'http://localhost'
		else 'http://46.4.19.13:30980'
	# create custom instance
	window.soFetch := httpFetch.create {
		baseUrl: server + '/api/http-fetch'
		timeout: 0
	}
	# check remote server avialability
	if not isLocal
		# check remote
		console.log 'httpFetch: remote version is '+(await soFetch '')
		if (await soFetch '/tests') != true
			window.soFetch := null
			console.log 'httpFetch: test interface is disabled'
			return
	# check test loaded
	if not window.test
		w3ui.log 'test() function is not defined'
		return
	###
	# httpFetch's asserter
	# it binds title and flag and
	# accepts httpFetch result to check
	window.assert = (title, expect) ->
		title = '%c'+title
		(res) !->
			###
			if res instanceof Error
				if res.hasOwnProperty 'id'
					res = 'FetchError('+res.id+')['+res.status+']: %c'+res.message+' ';
				else
					res = 'Error: %c'+res.message;
				expect := !expect
			else
				res = 'success(%c'+res+')';
			###
			expect := if expect
				then 'color:green'
				else 'color:red'
			###
			font = 'font-weight:bold;'
			console.log title+'%c'+res, font, font+expect, expect
	window.help = {
		base64ToBuf: (str) -> # {{{
			# decode base64 to string
			a = atob str
			b = a.length
			# create buffer
			c = new Uint8Array b
			d = -1
			# populate
			while ++d < b
				c[d] = a.charCodeAt d
			# done
			return c
		# }}}
		bufToHex: do -> # {{{
			# create conversion array
			hex = []
			i = -1
			n = 256
			while ++i < n
				hex[i] = i.toString 16 .padStart 2, '0'
			# create function
			return (buf) ->
				a = new Uint8Array buf
				b = []
				i = -1
				n = a.length
				while ++i < n
					b[i] = hex[a[i]]
				return b.join ''
		# }}}
	};
	window.sleep = (time) ->
		done = null
		setTimeout !->
			done!
		, time
		return new Promise (resolve) !->
			done := resolve
	###
	# set test's source code
	if a = document.querySelector 'code.javascript'
		a.innerHTML = test.toString!
	# highlight it
	hljs.initHighlighting!
	# }}}
	# RUN
	test!
###
