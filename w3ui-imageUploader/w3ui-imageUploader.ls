"use strict"
imageUploader = do ->
	# check requirements
	# {{{
	##### w3ui integration
	##### multiple file selection (option)
	##### ordering (option)
	##### instant upload (option)
	##### PHP object (back-end helper)
	# }}}
	# helpers
	hereDoc = (f) -> # {{{
		f = f.toString!
		a = f.indexOf '/*'
		b = f.lastIndexOf '*/'
		return f.substring a + 2, b - 1 .trim!
	# }}}
	htmlToElement = do -> # {{{
		temp = document.createElement 'template'
		return (html) ->
			temp.innerHTML = html
			return temp.content.firstChild
	# }}}
	# singletons & data
	# TODO {{{
	##### w3ui integration
	##### multiple file selection (option)
	##### ordering (option)
	##### instant update (option)
	##### backend support (PHP)
	# }}}
	store = new WeakMap!
	template = # {{{
		svgAdd: hereDoc !->
			/*
			<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
				<circle class="e1" cx="50" cy="50" r="49"/>
				<circle class="e2" cx="50" cy="50" r="46"/>
				<path class="e3" d="M64 17c0-1-1-2-2-2H38c-1 0-2 1-2 2v19H17c-1 0-2 1-2 2v24c0 1 1 2 2 2h19v19c0 1 1 2 2 2h24c1 0 2-1 2-2V64h19c1 0 2-1 2-2V38c0-1-1-2-2-2H64V17z"/>
				<path class="e4" d="M81 60H62c-1 0-2 1-2 2v19H40V62c0-1-1-2-2-2H19V40h19c1 0 2-1 2-2V19h20v19c0 1 1 2 2 2h19v20z"/>
			</svg>
			*/
		svgRemove: hereDoc !->
			/*
			<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
				<circle style="stroke: black; fill: white;" cx="50" cy="50" r="49"/>
				<circle style="stroke:none; fill:white;" cx="50" cy="50" r="46"/>
				<path style="stroke:none; fill:red;" d="M36 16c-1-1-2-1-3 0L16 33c-1 1-1 2 0 3l14 14-14 14c-1 1-1 2 0 3l17 17c1 1 2 1 3 0l14-14 14 14c1 1 2 1 3 0l17-17c1-1 1-2 0-3L70 50l14-14c1-1 1-2 0-3L67 16c-1-1-2-1-3 0L50 30 36 16z"/>
				<path style="stroke:none; fill:none;" d="M79 35L65 49c-1 1-1 2 0 3l14 14-14 14-14-14c-1-1-2-1-3 0L34 80 20 66l14-14c1-1 1-2 0-3L20 35l14-14 14 14c1 1 2 1 3 0l14-14 14 14z"/>
			</svg>
			*/
		item: hereDoc !->
			/*
			<div class="item">
				<div class="preview">
					<div class="box"><img></div>
				</div>
				<div class="remover">
					<div class="box">{{svgRemove}}</div>
				</div>
			</div>
			*/
		upload: hereDoc !->
			/*
			<div class="upload">
				<div class="box">{{svgAdd}}</div>
			</div>
			*/
	# }}}
	api = # {{{
		get: (data, k) ->
			# properties
			switch k
			case 'type'
				return 'w3ui-image-uploader'
			case 'readonly', 'readOnly'
				return data.readonly
			case 'value'
				return data.getMetadata!
			# nothing
			return null
		set: (data, k, v) ->
			switch k
			case 'readonly', 'readOnly'
				data.setReadonly !!v
			case 'value'
				if typeof! v == 'Array'
					return data.setItems v
			# done
			return true
	# }}}
	# constructors
	Item = (data, index, src) !-> # {{{
		# prepare template
		a = template.item.replace /{{svgRemove}}/g, template.svgRemove
		# create object shape
		@node     = htmlToElement a
		@index    = index
		@src      = src
		@preview  = @node.children.0.children.0
		@remover  = @node.children.1.children.0
		@remove   = @remove data
		@image    = @preview.children.0
		@input    = null
		@detached = false
		# initialize
		if src
			# set image attributes
			a = @image
			a.src = data.srcBase + src
			a.alt = ''
		else
			# create detached uploader input
			# (attached input will not trigger file selection)
			@input = a = document.createElement 'input'
			a.name = b + '[]' if b = data.name
			a.type = 'file'
			a.accept = 'image/*'
			a.addEventListener 'input', @inject data
		# set event handlers
		@preview.addEventListener 'click', @open data
		@remover.addEventListener 'click', @remove
	# }}}
	Item.prototype = # {{{
		open: (data) -> !~> # {{{
			if @detached
				@preview.classList.remove 'detached'
				@detached = false
			else
				@preview.classList.add 'detached'
				@detached = true
		# }}}
		remove: (data) -> (force) !~> # {{{
			# check
			if force or not data.readonly
				# detach element from the DOM
				@node.remove!
				# remove item data
				a = data.items.indexOf @
				data.items.splice a, 1
				--data.count
				# update item indeces
				while a < data.count
					--data.items[a].index
					++a
				# enable uploader
				if not data.readonly
					a = data.upload.classList
					if data.count < data.limit and not a.contains 'enabled'
						a.add 'enabled'
		# }}}
		inject: (data) -> (e) !~> # {{{
			# checkout files
			if not (a = @input.files) or not a.length
				# no files selected..
				return
			# take first file and check its type
			@src = a = a.0
			if not a.type.startsWith 'image/'
				# wrong type
				return
			# initialize selected image
			b = @image
			b.alt = a.name
			b.src = window.URL.createObjectURL a
			b.addEventListener 'load', !~>
				window.URL.revokeObjectURL @image.src
			# inject item
			if @index == data.count
				# APPEND
				data.items[data.count] = @
				data.node.insertBefore @node, data.upload
			else
				# INSERT
				# shift items
				a = @index
				b = data.items[a]
				while ++a <= data.count
					data.items[a] = data.items[a - 1]
				# set
				data.items[@index] = @
				data.node.insertBefore @node, b.node
			# add input
			@node.appendChild @input
			# disable upload
			if ++data.count >= data.limit
				data.upload.classList.remove 'enabled'
		# }}}
	# }}}
	Data = (node, opts) !-> # {{{
		# create object shape
		@node     = node
		@srcBase  = opts.srcBase or ''
		@name     = opts.name or ''
		@limit    = opts.limit or 4
		@readonly = !!opts.readonly
		@maxSize  = opts.maxSize or 0
		@items    = []
		@itemsIn  = []
		@count    = 0
		@upload   = upload = htmlToElement template.upload.replace /{{svgAdd}}/g, template.svgAdd
		# initialize
		# determine name
		if not @name and node.hasAttribute 'name'
			@name = node.getAttribute 'name'
		# wipe current content
		node.innerHTML = ''
		node.className += ' readonly' if @readonly
		# set uploader
		node.appendChild upload
		# set items (after uploader!)
		if opts.items
			@setItems opts.items
		else
			@setItems []
		# set event handlers
		upload.children.0.addEventListener 'click', (e) !~>
			# file selection trigger
			# prepare
			e.preventDefault!
			e.stopPropagation!
			# check
			if not @readonly and @count < @limit
				# create new item
				a = new Item @, @count, ''
				# trigger file selection
				a.input.click!
		# done
	# }}}
	Data.prototype = # {{{
		getMetadata: -> # {{{
			# prepare
			F = {length: 0}
			A = []
			R = null
			O = null
			# determine items for the upload (creation)
			a = @items
			a = 0
			for b in @items when b.input
				A[a] = b.index
				F[a] = b.src
				++a
			F.length = a
			# determine items for removal and ordering
			for a,b in @itemsIn
				if (@items.indexOf a) == -1
					R = [] if not R
					R[*] = b
				else if a.index != b
					O = {} if not O
					O[b] = a.index
			# check
			if not F.length and not R and not O
				return null
			# assemble
			F.add    = A if F.length
			F.remove = R if R
			F.order  = O if O
			return F
		# }}}
		setItems: (items) -> # {{{
			# remove all current items
			while @count
				@items.0.remove true
			# set new count
			if (@count = items.length) > @limit
				@count = @limit
			# add new items
			a = -1
			while ++a < @count
				@items[a] = b = new Item @, a, items[a]
				@node.insertBefore b.node, @upload
			# set initial items
			@itemsIn = @items.slice!
			# check
			if not @readonly and @count < @limit
				@upload.classList.add 'enabled'
			# done
			return true
		# }}}
		setReadonly: (flag) !-> # {{{
			# check
			if @readonly != flag
				# set
				if @readonly = flag
					@node.classList.add 'readonly'
					@upload.classList.remove 'enabled'
				else
					@node.classList.remove 'readonly'
					if @count < @limit
						@upload.classList.add 'enabled'
			# done
		# }}}
	# }}}
	# factory
	return (node, opts) -> # {{{
		# checkout global storage
		if not opts
			return if store.has node
				then store.get node
				else null
		# create new uploader
		x = new Proxy (new Data node, opts), api
		# store it
		store.set node, x
		# done
		return x
	# }}}
/***/
