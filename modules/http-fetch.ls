``export default `` do ->>
	# load httpFetch
	# from the upper level
	a = '../../httpFetch/httpFetch.js'
	a = await fetch a
		.then (r) ->>
			return r.text!
		.catch ->
			return null
	# check
	if not a
		return null
	# create constructor
	a = a.substring (a.indexOf 'httpFetch = ') + 12
	a = new Function '"use strict";return '+a
	# construct
	return a!
/***/
