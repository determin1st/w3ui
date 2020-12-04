``export default `` do ->>
	# load main code
	# from the upper level
	a = '../w3ui.js'
	a = await fetch a
		.then (r) ->>
			return r.text!
		.catch ->
			return null
	# check
	if not a
		return null
	# create constructor
	a = a.substring (a.indexOf 'function')
	a = new Function '"use strict";return '+a
	# construct
	return a!
/***/
