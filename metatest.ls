#######################
# constructors battle #
#######################
metaconstruct = (props) ->
	a = -1
	b = props.length
	c = ''
	while ++a < b
		c += 'this.'+props[a]+'=null;'
	return eval '(function(){'+c+'})'
######
# VS #
######
lolconstruct = (props) -> !->
	for prop in props
		@[prop] = null
##########
# FIGHT! #
##########
A = metaconstruct ['p1' 'p2' 'p3']
a = new A!
b = new A!
console.log (a == b) # false
console.log (a instanceof A) # true
console.log (b instanceof A) # true
console.log (a instanceof b.constructor) # true
A = lolconstruct ['p1' 'p2' 'p3']
a = new A!
b = new A!
console.log (a == b) # false
console.log (a instanceof A) # true
console.log (b instanceof A) # true
console.log (a instanceof b.constructor) # true
###########
console.log '============================='
###########
metaconstruct = do ->
	map = new WeakMap!
	lolconstruct = (props) -> !->
		for prop in props
			@[prop] = null
	return (props) ->
		if not (a = map.get props)
			map.set props, (a = lolconstruct props)
		return a
##########
# FIGHT! #
##########
A = ['p1' 'p2' 'p3']
a = new (metaconstruct A)!
b = new (metaconstruct A)!
console.log (a instanceof b.constructor) # true
console.log (b instanceof a.constructor) # true
console.log (b instanceof (metaconstruct A)) # true
a = new (lolconstruct A)!
b = new (lolconstruct A)!
console.log (a instanceof b.constructor) # false
console.log (b instanceof a.constructor) # false
console.log (b instanceof (lolconstruct A)) # false

