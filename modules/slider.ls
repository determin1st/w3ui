"use strict"
false and w3ui.slider = {
    /* {{{
    * rev90, TODO:
    * task #10: slider constructor
    * negative values
    * large values
    * multiple handles >2
    * multiple ranges, minmax, array
    * <-(arrow capture keys)-> with acceleration
    * GSAP animation
    * better sync for handle/range animation
    * new standard with slash(/) syntax in border-radius
    * revise relative option
    * optimize range refresh routine
    * image slider
    */
    options: # {{{
        ORDER:
            'minmax'
            'count'
            'step'
            'margin'
            'value'
        # LOGIC
        minmax: [0, 100]    # default min and max values (order matters)
        count: 1            # number of handles/values of the slider
        step: 1             # value step, >1 are meaningful
        margin: []          # margin between two close values (not borders)
        value: [0]          # value for each handle
        # VISUAL
        range: [0, 0]       # range map (including borders)
        orientation: true   # horizontal or vertical slider
        strict: false       # strict handle positioning
        inner: false        # handle is inside the scale
        round: 0            # 1=rounded scale, 2=rounded handles 3=round handles
        # INTERACTION
        tabindex: -1        # handle attribute
        toggle: false       # toggles handle position to the nearest value in step-slider
        # KEYBOARD
        k_pages: 5          # count of pages (PgUp/PgDown) in a slider
        k_range:            # range control keys
            'ctrlKey'
            'HOME'          # -> border
            'END'           # -> center
        k_value:            # value history control
            'ctrlKey'
            'LEFT'          # -> undo
            'RIGHT'         # -> redo
    # }}}
    data: # {{{
        handles: null       # handle elements
        handleIndex: -1     # active handle
        maxCount: 10        # maximum handle count
        min: 0              # minimal value
        max: 100            # maximal value
        shift: 0            # value shift to make values positive
        size: 100           # max - min
        margin: 0           # sum of margins
        val: null           # refined values
        scale: null         # scale parameters
    # }}}
    ###
    create: -> # {{{
        # prepare
        data = @data
        opts = @options
        # handles
        # {{{
        # get children
        a = @node.query ''
        # check count
        b = a.length
        c = opts.count
        if b != c
            if b > c
                # more than required,
                # remove from DOM
                for d from b - 1 to c - 1
                    @node.child.remove a[d].node
            else
                # less than required,
                # add to DOM
                for d from 0 to c - b
                    # create new
                    a = document.createElement 'div'
                    # add
                    @node.child.add a
            # re-query
            a = @node.query ''
        # set base class
        a.class.add 'ui-'+@name+'-handle'
        # enable focus
        a.prop.tabindex = opts.tabindex
        # add indexes
        for b,c in a
            b.prop.dataIndex = c + 1
        # TODO
        # add size and position
        # ..
        a.size = @getHandleSize!
        a.pos  = d.handleSize.map -> {left: 0, top: 0}
        # save result
        d.handles = a
        ### }}}
        # ranges
        # {{{
        if d.range
            # проверка существования
            if not d.range$
                # создаем DOM элементы диапазона
                b = []
                for a from 0 to d.range.length when d.range[a] >= 0
                    a = document.createElement \div
                    b.push a
                    @element.append a
                # оборачиваем
                b = $ b
                # добавляем стиль и нумерацию
                b.addClass @name + "-range"
                b.each (index) -> b.eq index .addClass \n + (index + 1)
                # сохраняем
                d.range$ = $ b
            # убираем атрибуты позиционирования
            d.range$.css {
                left: ""
                top:  ""
            }
            # добаваляем специальный стиль
            # для диапазонов привязанных к началу и концу шкалы
            a = [\min \max]
            b = d.range.length - 1
            o.direction and a.reverse!
            d.range[0] < 0 and d.range.element.eq 0 .addClass a.0
            d.range[b] < 0 and d.range.element.eq b .addClass a.1
        # удаляем диапазон
        else if d.range$
            d.range$.remove!
            delete d.range$
        ### }}}
        # done
        @refresh true
        return true
    # }}}
    setup: (key, val) -> # {{{
        # prepare
        dat = @data
        opt = @options
        msg = (msg) ~> @log 'incorrect option «'+key+'», '+msg
        switch key
        | 'minmax' =>
            # {{{
            # check type
            if not ('length' of val)
                msg 'wrong type'
                return
            if val.length != 2
                msg 'incorrect length'
                return
            # convert to integers
            val =
                Math.round val.0
                Math.round val.1
            # check values
            if val.0 == val.1
                msg 'values cant be equal'
                return
            # determine scale direction
            a = val.slice!
            dat.reversed = a.0 < a.1
            # reorder
            a.reverse! if dat.reversed
            # define shift (support for negative numbers)
            dat.shift = if a.0 < 0
                then -a.0
                else 0
            # apply shift (we work only with positive numbers)
            if dat.shift
                a.0 = 0
                a.1 = a.1 + dat.shift
            # store
            dat.min = a.0
            dat.max = a.1
            dat.size = a.1 - a.0
            # }}}
        | 'count' =>
            # {{{
            # prepare
            val = Math.round val
            # check
            if val <= 0
                msg 'must be greater than zero'
                val = 1
            # apply limit
            if val > dat.maxCount
                msg 'must be less than '+dat.maxCount
                val = dat.maxCount
            # correct related options
            if val > opt.count
                for a from opt.count to val
                    opt.margin.push 0
                    opt.value.push opt.value[* - 1]
                    opt.range.push 0
            else if val < opt.count
                for a from val to opt.count
                    opt.margin.pop!
                    opt.value.pop!
                    opt.range.pop!
            # }}}
        | 'step' =>
            # {{{
            # prepare
            val = Math.round val
            # check borders
            # bottom
            if val <= 0
                msg 'should be positive'
                val = 1
            # top
            a = Math.round((dat.max - dat.min) / opt.count)
            if val > a
                msg 'must be less than '+a
                val = a
            # }}}
        | 'margin' =>
            # {{{
            # prepare
            val = val.map (val) ->
                # take only integers
                val = Math.round val
                # check
                if val < 0
                    msg 'should be positive'
                    val = 0
                # align with step
                if (a = val % opt.step) != 0
                    msg 'should be aligned with the step '+opt.step
                    val -= a
                # done
                val
            # calculate sum
            a = val.reduce (a, b) ->
                a + b
            , 0
            # check it
            b = dat.max - dat.min - a
            c = Math.round a / opt.step
            if b <= 0 or c < opt.count
                msg 'the total margin '+a+' is too big'
                return
            # save sum
            dat.margin = a
            # }}}
        | 'value' =>
            # {{{
            # check borders
            # bottom
            if val.length < opt.count
                msg 'minimum '+opt.count+' items required'
                return
            # top
            if val.length > opt.count
                msg 'limited by '+opt.count
                val = val.slice 0, opt.count
            # prepare
            # take only integers
            # sorted in ascending order
            v = val.map (v) ->
                Math.round v
            .sort (a, b) ->
                if a < b then -1 else 1
            # apply shift
            dat.shift and v = v.map (v) ->
                v + dat.shift
            # apply border limits
            for a,b in v
                v[b] = dat.min if a < dat.min
                v[b] = dat.max if a > dat.max
            # apply margins
            if dat.margin
                m = opt.margin
                for a,b in m when a > 0
                    # check if value margin is okay
                    # with the next value
                    if (c = v[b + 1] - v[b]) >= a
                        # okay
                        continue
                    # not okay
                    # determine shift size
                    c = a - c
                    # determine which value could be shifted
                    # check current (first)
                    a = v[b] - c
                    if (b == 0 and a >= dat.min) or (v[b - 1] + m[b - 1] >= a)
                        # okay, shift
                        v[b] = a
                        continue
                    # check next (last)
                    a = v[++b] + c
                    if (b >= m.length and a <= dat.max) or (v[b + 1] - a >= m[b])
                        # okay, shift
                        v[b] = a
                        continue
                    # shift is not possible!
                    # dont change values
                    msg 'failed to apply margins'
                    return
            # save result
            dat.val = v
            # }}}
        | 'range' =>
            # {{{
            # prepare
            val = val.map (val) -> !!val
            # check and fix length
            # bottom
            a = opt.count + 1
            while val.length < a
                val.push false
            # top
            val.slice 0, a if val.length > a
            # }}}
        | 'toggle' =>
            # {{{
            # prepare
            val = !!val
            # check
            if opt.count == 1 and val
                msg 'supported only for a single handle'
                val = false
            # }}}
        | 'orientation' =>
            # {{{
            # prepare
            a = if val
                then 'horizontal'
                else 'vertical'
            # set style
            @node.class.add 'ui-'+@name+'-'+a
            # }}}
        | 'tabindex' =>
            # {{{
            # determine value
            if val != null
                val = if isNaN (a = parseInt val)
                    then null
                    else a
            # set attribute
            @node.prop.tabindex = null
            # }}}
        | otherwise =>
            msg 'not implemented'
            return
        # done
        return val
    # }}}
    refresh: (init) -> # {{{
        # prepare
        d = @data
        o = @options
        # scale {{{
        # determine element size and position
        a = @element.0
        a =
            left:   a.offsetLeft
            top:    a.offsetTop
            height: a.offsetHeight
            width:  a.offsetWidth
            h:      a.clientHeight
            w:      a.clientWidth
            margin: 0
            handle: 0
        # apply scroll offset
        @element.parents!each (index, el) !->
            a.left += el.scrollLeft
            a.top  += el.scrollTop
        # determine scale and fixed axis size
        b = if o.orientation
            then [a.w a.h]
            else [a.h a.w]
        # determine margin size
        if d.margin
            # determine relative value
            c = d.margin / d.size
            # determine absolute value
            a.margin = b.0 * c
        # determine default handle size
        a.handle = if o.inner
            then b.1
            else 1.5 * b.1
        # determine border curvature
        c = if o.round
            then @cssValue b.1 / 2
            else ""
        # apply it
        @element.css "border-radius", c
        # save results
        d.scale = a
        # }}}
        # handles {{{
        a = []
        d.handles.each (index, node) !->
            # for each handle
            # determine element geometry
            b =
                w:      node.clientWidth
                h:      node.clientHeight
                width:  node.offsetWidth
                height: node.offsetHeight
                w_gap:  0
                h_gap:  0
            # ..
        # ..
        /***
        # определим классификаторы фиксированной оси и шкалы
        a = ["h", "height", "innerHeight", "outerHeight", "h_gap"];
        b = ["w", "width",  "innerWidth",  "outerWidth",  "w_gap"];
        @orientation && (d = a, a = b, b = d);
            # ..
            # prepare
            #node = d.handles.eq index
            # добавляем индекс
            #node.data "ui-slider-handle-index", index
            # определяем зазор
            d[a[4]] = el[a[3]](true) - d[a[0]];
            d[b[4]] = el[b[3]](true) - d[b[0]];
            # определяем полный размер ползунка
            # фиксированная ось
            c = @elementSize.handle;# авто-размер
            # в случае, если текущий стиль не конфликтует с опциями,
            # оставляем его, иначе назначаем авто-размер.
            d[a[1]] = (d[a[0]] > 1 && (!@options.inner || d[a[0]] < c)) ?
                    (d[a[0]] + d[a[4]]) : c;
            # шкала
            d[b[1]] = (d[b[0]] > 1) ?
                    (d[b[0]] + d[b[4]]) : c;
            # определяем внутренний размер
            d[a[0]] = Math.abs(d[a[1]] - d[a[4]]);
            d[b[0]] = Math.abs(d[b[1]] - d[b[4]]);
            # кривизна границ
            c = @options.round;
            if (c > 1)
            {
                # закругленные границы
                # в зависимости от внутреннего размера ползунка на фиксированной оси
                d["border-radius"] = @_cssValue(d[a[0]] / 2);
                # круглый ползунок
                if (c > 2)
                {
                    # размеры симметричны (длина == ширина)
                    # за основу берем размер на фиксированной оси
                    d[b[0]] = d[a[0]];
                    d[b[1]] = d[b[0]] + d[b[4]];
                    d["border-radius"] = "50%";
                }
            }
            # определим соотношение внутренних размеров
            d.scale = d[b[0]] / d[a[0]]; # плавающая / фиксированная
            # сохраняем
            e[index] = d;
            true

        # определяем размер



        e = [];


        @handles.toArray!forEach(function(el, index) {
        }, this);




        # align on fixed axis
        d.handles.each (index, node) !->
            # determine offset (center)
            d = @handleSize[index];
            e = @elementSize[b[0]];
            e = [
                d[b[0]],
                e / 2.0 - d[b[1]] / 2.0,
                e,
                "border-radius"
            ]
            # проверка необходимости
            if (Math.abs(node[b[3]]() - e[0]) > 0.0001 ||
                Math.abs(@handleOffset[index][b[2]] - e[1]) > 0.0001)
            {
                # выполняем позиционирование
                # без анимации
                a = {};
                a[b[1]] = @_cssValue(e[0], e[2]);
                a[b[2]] = @_cssValue(e[1], e[2]);
                if (d[e[3]]) {
                    a[e[3]] = d[e[3]];
                }
                node.css(a);
            }
        # ..











        # ..
        a = ["w", "width",  "left", "innerWidth",  "outerWidth",  "w_gap"]
        b = ["h", "height", "top",  "innerHeight", "outerHeight", "h_gap"]
        @orientation && (c = a, a = b, b = c);
        # collect handles
        for (c = [], d = 0; d < @val.length; d++) {
            c[d] = @handles.eq(d);
        }
        # 1. позиционируем на шкале
        # {{{
        # вычисляем полный размер
        d = @handleSize;
        d.full = 0;
        c.forEach(function(node, index) {
            # подготовка
            e = d[index];
            # размер на шкале пропорционален размеру на фиксированной оси
            # внутренний размер
            e[a[0]] = e.scale * e[b[0]];
            # полный размер
            e[a[1]] = e[a[0]] + e[a[5]];
            d.full += e[a[1]];
        });
        # позиционирование
        c.forEach(function(node, index) {
            # обновляем размер
            # без анимации
            d = @_cssValue(@handleSize[index][a[0]], @elementSize[a[0]]);
            e = {}, e[a[1]] = d;
            node.css(e);
            # обновляем смещение
            # с условной анимацией
            @_refreshHandle(index, !fixedAxis);
        }, this);
        # }}}
        /***/
        # }}}
        # ranges {{{
        @refreshRange!
        # }}}
        # complete
        true
    # }}}
    addEvents: -> # {{{
        ##
        /***
        # определяем обработчики
        # клавиатура
        a = @handles;
        b = function(type) {
            return function(e) {
                return @_event(type, e, $(e.target).data("ui-slider-handle-index"));
            }
        }
        @_off(a);
        @_on(a, {keydown: b("keydown"), keyup: b("keyup")});
        @_hoverable(a);
        @_focusable(a);
        # указатель
        @_mouseInit!
        # изменение размеров
        a = $(window);
        b = "resize." + @eventNamespace;
        a.off(b) && a.on(b, jQuery.proxy(@refresh, this));
        ##
        return true;
        /***/
    # }}}
    event: -> # {{{
        true
        /*** TODO
        _event: function(name, event, index, val) { # {{{
            var a, b, c, d, e;
            var trigger;
            ##
            arguments.length < 3 && (index = -1);
            ##
            trigger = function (val) {
                # {{{
                # подготовка
                a = index >= 0 ? index : 0;
                b = @val;
                c = val ? val : b;
                # подготовка параметра
                a = {
                    handle:         @handles[a],
                    handleIndex:    a,
                    value:          @_valueRefined(c[a], true),
                    values:         @_valueRefined(c, true),
                    programmatic:   !event
                };
                # новое значение
                @val = c;
                # отправляем событие
                a = @_trigger(name, event, a);
                if (val)
                {
                    if (a)
                    {
                        # успех
                        # обновляем конфигурацию
                        @options.values = c;
                        # обновляем ползунки
                        index >= 0 ?
                            @_refreshHandle(index, true) :
                            @_refreshHandles!
                    }
                    else
                    {
                        # провал
                        # восстанавливаем значение
                        @val = b;
                    }
                }
                return a;
                # }}}
            }
            switch (name)
            {
                case "slide":
                    # {{{
                    # пустое событие, change
                    if (index < 0 || val === undefined) {
                        break;
                    }
                    # проверка необходимости
                    if (val === @val[index]) {
                        return false;
                    }
                    # конвертируем значение в массив
                    val = @val.map(function(a, b) {
                        return index === b ? val : a;
                    });
                    break;
                    # }}}
                case "change":
                    # {{{
                    # проверка
                    if (@_capture) {
                        return false;
                    }
                    # определяем значение
                    a = val ? val : @val;
                    b = @_val;
                    # не срабатывает при неизменном значении
                    if (b && b.toString() === a.toString()) {
                        return true;
                    }
                    # сохраняем
                    @_val = a.slice!
                    if (!trigger.apply(this, [a]))
                    {
                        @_val = b;
                        return false;
                    }
                    # дополнительное событие
                    # при взаимодействии с пользователем
                    @_event("slide", event, index);
                    return true;
                    # }}}
                case "start":
                    # {{{
                    # вызываем пользовательский обработчик
                    if (!trigger.apply(this)) {
                        return false;
                    }
                    # сохраняем индекс
                    @_handleIndex = index;
                    # определяем ползунок
                    a = @handles.eq(index);
                    if (!@options.toggle)
                    {
                        # захват ввода
                        @_capture = true;
                        # инициируем получение фокуса
                        a.trigger("focus");
                    }
                    # устанавливаем стиль
                    @_toggleClass(a, null, "ui-state-active", @_capture);
                    # передвигаем ползунок
                    if (!a.hasClass("ui-state-hover") || @options.toggle) {
                        @_event("slide", event, index, val);
                    }
                    return true;
                    # }}}
                case "stop":
                case "keyup":
                    # {{{
                    @_capture = false;
                    @_handleIndex = -1;
                    @_removeClass(@handles, null, "ui-state-active");
                    trigger.apply(this) && @_event("change", event);
                    return true;
                    # }}}
                case "keydown":
                    # {{{
                    # подготовка
                    # {{{
                    # определяем нажатие управляющих клавиш
                    a = $.ui.keyCode;
                    b = [

                        # basic 0-3
                        a.HOME,
                        a.END,
                        a.PAGE_UP,
                        a.PAGE_DOWN,

                        # slide 4-7
                        a.LEFT,
                        a.RIGHT,
                        a.DOWN,
                        a.UP,

                        # range 8-9
                        a[@options.k_range[1]],  # max
                        a[@options.k_range[2]]   # min
                    ];
                    # проверяем клавиши управления ползунком
                    # если неизвестная клавиша, обработчик по-умолчанию
                    if ((a = jQuery.inArray(event.keyCode, b)) < 0) {
                        return true;
                    }
                    # проверяем клавиши управления диапaзоном
                    if (event[@options.k_range[0]] &&
                        (c = jQuery.inArray(b[a], b, 8)) >= 0)
                    {
                        # проверяем наличие диапазона
                        if (!@_rangeMap) {
                            return false;
                        }
                        a = c;
                    }
                    # проверка завершена
                    # отключаем обработчик по-умочанию
                    event.preventDefault!
                    # инициируем событие
                    if (a >= 4 && a <= 7)
                    {
                        # выполняем захват ввода для медленных перемещений
                        if (!@_capture && !@_event("start", event, index)) {
                            return false;
                        }
                    }
                    else
                    {
                        # отключаем захват
                        @_capture = false;
                    }
                    # определяем ползунок
                    b = @handles.eq(index);
                    # определяем допустимые значения
                    c = [
                        @_valueMin(index),
                        @_valueMax(index),
                        @orientation,
                        @options.direction
                    ];
                    # определим размер шага (минимальный инкремент)
                    b = @step > 1 ? (@max - @min) / @step : 1;
                    # определяем текущeе значениe без отступа
                    d = @val[index];
                    d = @_valueTrim(d, index, true);
                    # }}}
                    # вычисляем новое значение
                    # {{{
                    do
                    {
                        # single value change
                        if (a <= 7) {
                            if (a <= 1) # HOME, END
                            {
                                # home is located above in keyboards,
                                # so the key-geometry is more important in visual
                                # representation of vertical slider.
                                # math logic is chosen for horizontal: HOME=min,END=max
                                if ((c[2] &&
                                    ((c[3]  && a === 1) ||
                                    (!c[3] && a === 1))) ||
                                    (!c[2] &&
                                    ((c[3]  && a === 1) ||
                                    (!c[3] && a === 0))))
                                {
                                    b = -c[1];
                                }
                                else {
                                    b = c[1];
                                }
                            }
                            else if (a <= 3) # PAGE_UP, PAGE_DOWN
                            {
                                # page-aligned increment
                                # same logic (as above) is used for PGUP/PGDOWN..
                                e = (c[1] - c[0]) / @k_pages;
                                b = e > b ? e : b;
                                if ((c[2] && a === 3) ||
                                    (!c[2] &&
                                    ((c[3] && a === 2) ||
                                    (!c[3] && a === 3))))
                                {
                                    b = -b;
                                }
                            }
                            else
                            {
                                # step-aligned increments
                                # LEFT/RIGHT are geometry based for horizontal slider
                                # and algebra based for vertical.
                                # DOWN/UP are reversed to LEFT/RIGHT.
                                #
                                #        4.LEFT,
                                #        5.RIGHT,
                                #        6.DOWN,
                                #        7.UP
                                #
                                if ((c[2] &&
                                    ((c[3]  && (a === 5 || a === 6)) ||
                                    (!c[3] && (a === 4 || a === 6)))) ||
                                    (!c[2] &&
                                    ((c[3]  && (a === 4 || a === 7)) ||
                                    (!c[3] && (a === 4 || a === 6)))))
                                {
                                    b = -b;
                                }
                            }
                            # добавляем смещение
                            d += b;
                            d < c[0] && (d = c[0]);
                            d > c[1] && (d = c[1]);
                            d = @_valueTrim(d, index);
                            break;
                        }
                        # изменение нескольких значений
                        # range
                        if (a <= 9) { # Ctrl+HOME/END
                            if (a === 8)
                            {
                                # минимум
                                # определим среднее значение
                                d = @min + (@max - @min) / 2;
                                d = d - @options.margin / 2;
                                d = @_valueTrim(d);
                                e = d + @options.margin;
                                e > @max && (e = @max);
                                d = [d, e];
                            }
                            else
                            {
                                # максимум
                                d = [@min, @max];
                            }
                            break;
                        }
                    }
                    while (0);
                    # }}}
                    # передаем изменения обработчикам
                    if (@_capture) {
                        @_event("slide", event, index, d);
                    }
                    else
                    {
                        # возможно изменение одного или нескольких значений
                        if (!jQuery.isArray(d))
                        {
                            d = @val.map(function(val, idx) {
                                return idx === index ? d : val;
                            });
                        }
                        else {
                            index = -1;
                        }
                        @_event("change", event, index, d);
                    }
                    return false;
                    # }}}
                otherwise:
                    val = false;# значение неизменно
                    break;
            }
            return trigger.apply(this, [val]);
        },
        # }}}
        /***/
    # }}}
    delEvents: -> # {{{
        # отключаем указатель
        @_mouseDestroy!
        # отключаем события слайдера
        @_off(@handles);
        # отключаем обработчик изменения размеров
        $(window).off "resize."+@eventNamespace
    # }}}
    destroy: -> # {{{
        # отстыковка обработчиков
        @delEvents!
        # удаление элементов
        d = @data
        d.handle.remove!
        delete d.handle
        delete d.handleSize
        delete d.handleOffset
        if d.range$
            d.range$.remove!
            delete d.range$
        # возврат
        true
    # }}}
    ###
    api: # {{{
        alias:
            value: [\val \value \values]
            range: [\range \ranges]
        # getters and setters
        /***
        value: function(val, index) { # {{{
            var a, b;
            ##
            a = arguments.length;
            if (!a) {
                return @values(0);
            }
            b = typeof val;
            if (b !== "number" && b !== "string") {
                return false;
            }
            if (a === 1) {
                return @values(0, val);
            }
            if (index < 0 || index >= @val.length) {
                return false;
            }
            return @values(index, val);
        },
        # }}}
        values: function(index, val) { # {{{
            var a, b, c;
            ##
            # подготовка
            a = arguments.length;
            b = arguments[0];
            # возвращаем все значения
            if (a === 0) {
                return @_valueRefined(@val, true);
            }
            # сохраняем массив значений
            if (a === 1 && jQuery.isArray(b))
            {
                if (!@_event("change", null, -1, @_valueRefined(b))) {
                    return b;
                }
                return @_valueRefined(b, true);
            }
            # сохраняем единственное значение
            if (a === 2)
            {
                b = @_valueRefined(val);
                c = @val.slice!
                c[index] = b;
                return @_event("change", null, index, c) ? b : false;
            }
            # возвращаем единственное значение
            return @_valueRefined(@val[index]);
        },
        # }}}
        range: function(index) { # {{{
            index = arguments.length ? 0 + index : 0;
            return @ranges(index);
        },
        # }}}
        ranges: function() { # {{{
            var a, b, c, d;
            ##
            if (!@_rangeMap) {
                return false;
            }
            # подготовка
            a = arguments.length;
            b = [];
            for (c = 0; c < @_rangeMap.length; c += 2)
            {
                d = [
                    @_rangeMap[c],
                    @_rangeMap[c + 1]
                ];
                @options.direction && d.reverse!
                d[0] = d[0] < 0 ? @min : @val[d[0]];
                d[1] = d[1] < 0 ? @max : @val[d[1]];
                b.push(Math.abs(d[1] - d[0]));
            }
            # возврат
            if (a === 0) {
                return b;
            }
            a = index < 0 || index >= b.length ? 0 : index;
            return b[a];
        },
        # }}}
        /***/
    # }}}
    ###
    cssValue: (val, scale) -> # convert pixels to % {{{
        # convert
        if scale
            # use scale as base
            a = ((100.0 * val / scale).toFixed 5) + "%"
        else
            # align value
            a = (Math.round val) + "px"
        # done
        a
    # }}}
    # TODO:
/** {{{ **
    # MOUSE
    _mouseEventCoords: function(e) { # {{{
        var a, b, c;
        ##
        # определим относительную позицию указателя
        # вычисляем scroll
        a = {x: e.pageX, y: e.pageY};
        b = @element.parents!
        for (c = 0; c < b.length; c++)
        {
            a.x = a.x + b.eq(c).scrollLeft!
            a.y = a.y + b.eq(c).scrollTop!
        }
        return a;
    },
    # }}}
    _mouseValue: function(coords, capture) { # {{{
        var a, b, c, d, e;
        ##
        # определяем значение шкалы в месте клика
        # в зависимости от ориентации слайдера
        a = @orientation ?
            [coords.y - @elementOffset.top,  "height", "top"] :
            [coords.x - @elementOffset.left, "width", "left"];
        # определяем ближайший ползунок
        d = @_getClosestHandle(coords);
        # определяем длину шкалы
        b = @_getScaleSize(d, true);
        # определяем смещение (относительная позиция)
        c = (a[0] - b[0]) / b[1];
        # инвертируем в случае вертикального слайдера
        @orientation && (c = 1 - c);
        # проверка выхода за границы
        c > 1 && (c = 1);
        c < 0 && (c = 0);
        # вычисляем абсолютное значение
        a = [
            @_valueMin(d),
            @_valueMax(d)
        ];
        b = a[0] + c * (a[1] - a[0]);
        # определяем текущее значение
        c = @options.toggle ?
            @val[d] : @_valueTrim(b, d);
        # определяем шаг
        e = @step ? (@max - @min) / @step : 1;
        # корректировка
        if (Math.abs(@val[d] - c) < 0.0001 &&
            Math.abs(b - c) >= 1 && # минимальный инкремент
            (capture || @options.toggle))
        {
            # значение не может остатся неизменным в случае,
            # когда указатель выбирает точку на шкале
            c = c > b ? c - e : c + e;
        }
        # проверяем выход за границы
        c > a[1] && (c = a[1]);
        c < a[0] && (c = a[0]);
        # возврат
        return c;
    },
    # }}}
    _mouseCapture: function(e) { # {{{
        var a, b;
        ##
        # проверка
        if (@options.disabled) {
            return false;
        }
        # определяем координаты
        a = @_mouseEventCoords(e);
        b = @_mouseValue(a, true);
        # инициируем событие
        return @_event("start", e, @_getClosestHandle(a), b);
    },
    # }}}
    _mouseDrag: function(e) { # {{{
        ##
        if (@options.toggle) {
            return false;
        }
        @_event("slide", e, @_handleIndex, @_mouseValue(@_mouseEventCoords(e)));
        return true;
    },
    # }}}
    _mouseStop: function(event) { # {{{
        @_event("stop", event);
    },
    # }}}
    # POSITIONING
    refreshScale: !-> # {{{
        # prepare
        d = @data
        o = @options
        # determine element size and position
        a = @element.0
        a =
            left:   a.offsetLeft
            top:    a.offsetTop
            height: a.offsetHeight
            width:  a.offsetWidth
            h:      a.clientHeight
            w:      a.clientWidth
            margin: 0
            handle: 0
        # apply scroll offset
        @element.parents!each (index, el) !->
            a.left += el.scrollLeft
            a.top  += el.scrollTop
        # determine scale and fixed axis size
        b = if o.orientation
            then [a.w a.h]
            else [a.h a.w]
        # determine margin size
        if d.margin
            # determine relative value
            c = d.margin / d.size
            # determine absolute value
            a.margin = b.0 * c
        # determine default handle size
        a.handle = if o.inner
            then b.1
            else 1.5 * b.1
        # determine border curvature
        c = if o.round
            then @cssValue b.1 / 2
            else ""
        # apply it
        @element.css "border-radius", c
        # save results
        d.scale = a
    # }}}
    refreshHandles: (fixedAxis) !-> # {{{
        # prepare
        d = @data
        o = @options
        # ..
        a = ["w", "width",  "left", "innerWidth",  "outerWidth",  "w_gap"]
        b = ["h", "height", "top",  "innerHeight", "outerHeight", "h_gap"];
        @orientation && (c = a, a = b, b = c);
        # определяем массив ползунков
        for (c = [], d = 0; d < @val.length; d++) {
            c[d] = @handles.eq(d);
        }
        # 1. позиционируем на шкале
        # {{{
        # вычисляем полный размер
        d = @handleSize;
        d.full = 0;
        c.forEach(function(node, index) {
            # подготовка
            e = d[index];
            # размер на шкале пропорционален размеру на фиксированной оси
            # внутренний размер
            e[a[0]] = e.scale * e[b[0]];
            # полный размер
            e[a[1]] = e[a[0]] + e[a[5]];
            d.full += e[a[1]];
        });
        # позиционирование
        c.forEach(function(node, index) {
            # обновляем размер
            # без анимации
            d = @_cssValue(@handleSize[index][a[0]], @elementSize[a[0]]);
            e = {}, e[a[1]] = d;
            node.css(e);
            # обновляем смещение
            # с условной анимацией
            @_refreshHandle(index, !fixedAxis);
        }, this);
        # }}}
        # 2. позиционируем на фиксированной оси
        # {{{
        if (fixedAxis) {
            c.forEach(function(node, index) {
                # подготовка
                # определяем смещение (центровка)
                d = @handleSize[index];
                e = @elementSize[b[0]];
                e = [
                    d[b[0]],
                    e / 2.0 - d[b[1]] / 2.0,
                    e,
                    "border-radius"
                ]
                # проверка необходимости
                if (Math.abs(node[b[3]]() - e[0]) > 0.0001 ||
                    Math.abs(@handleOffset[index][b[2]] - e[1]) > 0.0001)
                {
                    # выполняем позиционирование
                    # без анимации
                    a = {};
                    a[b[1]] = @_cssValue(e[0], e[2]);
                    a[b[2]] = @_cssValue(e[1], e[2]);
                    if (d[e[3]]) {
                        a[e[3]] = d[e[3]];
                    }
                    node.css(a);
                }
            }, this);
        }
        # }}}
        # complete
    # }}}
    refreshHandle: function(index, animate) { # {{{
        var a, b, c, d, e;
        ##
        # подготовка
        # в зависимости от ориентации слайдера
        a = @orientation ?
            ["h", "height", "top"] :
            ["w", "width", "left"];
        # определяем ползунок
        b = @handles.eq(index);
        # определяем виртуальное смещение
        c = @_getHandleOffset(index);
        @handleOffset[index][a[2]] = c;
        # определяем флаг анимации
        d = (animate && @options.animate) ?
            @options.animate : 0;
        # определяем время анимации
        if (d)
        {
            # определяем текущую позицию
            e = b.position!
            # определяем дистанцию
            if ((e = Math.abs(c - e[a[2]])) < 0.0001) {
                # позиционирование не требуется
                return true;
            }
            # вычисляем относительное время анимации 1..0
            e = e / (@elementSize[a[0]] - @handleSize.full);
            # вычислем абсолютное время
            # отсекаем минимальные значения
            e = d * e / 2;
            d = e <= 50 ? 0 : (e < d ? d : e);
        }
        # определяем параметр
        e = {};
        e[a[2]] = @_cssValue(c, @elementSize[a[0]]);
        # позиционируем
        if (d)
        {
            # с анимацией
            # останавливаем текущую
            b.stop(@eventNamespace, true, @_capture);
            # запуск
            a = this;
            b.animate(e, {
                duration: d,
                queue: @eventNamespace,
                step: function(now, fx) {
                    # на каждом шаге анимации
                    # обновляем диапозон с текущим значением ползунка
                    a._refreshRange(a.handleOffset.map(function(val, idx) {
                        return idx === index ? b.position() : val;
                    }));
                },
                complete: function() {
                    # после завершения
                    a._refreshRange!
                }
            }).dequeue(@eventNamespace);
        }
        else
        {
            # без анимации
            # останавливаем текущую анимацию
            if (@options.animate) {
                b.stop(@eventNamespace, true, false);
            }
            # обновляем
            b.css(e);
            @_refreshRange!
        }
        return true;
    },
    # }}}
    refreshRange: function(queryPosition) { # {{{
        var a, b, c, d, e;
        ##
        # проверка
        if (!@_rangeMap) {
            return true;
        }
        # подготовка
        a = ["left", "width",  "w", "w_gap",    "h_gap", "h", "height","top"];
        @orientation && a.reverse!
        ##
        # 1. на шкале
        # определяем начальную/конечную точки
        b = @_rangeMap.slice!
        # инвертируем при необходимости
        c = [
            @orientation,
            @options.direction,
            @options.range === true
        ];
        if ((c[0] && (!c[1] || c[2])) ||    # вертикаль
            (!c[0] && (c[1] && !c[2])))     # горизонталь
        {
            b.reverse!
        }
        # диапазон
        # определяем позиции точек
        c = 0;
        d = 0;
        b = b.map(function(val, idx) {
            ##
            if (val < 0)
            {
                # граница
                # определим параметры связанного ползунка
                val = idx ? b[idx - 1] : b[idx + 1];
                val = @handleSize[val];
                d = val[a[3]];
                c = val[a[1]] - d;
                d = d / 2;
                # определим позицию
                e = idx ? @elementSize[a[2]] : 0;
                # добавляем зазор ползунка,
                # в случае, если его внутренний размер меньше
                # размера слайдера на фиксированной оси
                if (val[a[5]] <= @elementSize[a[5]]) {
                    e += (idx ? -1 : 1) * d;
                }
                else
                {
                    # ползунок больше слайдера,
                    # отступ не нужен
                    d = 0;
                }
            }
            else
            {
                # ползунок
                # определим позицию
                e = queryPosition ?
                    @handles.eq(val).position() : @handleOffset[val];
                e = e[a[0]];
                # корректируем
                # небольшой отступ в зависимости от позиции ползунка
                val = @handleSize[val];
                e += (idx & 1) ?
                    (val[a[1]] - val[a[3]] / 2) : val[a[3]] / 2;
            }
            return e;
        }, this);
        # определяем размер
        b[1] = Math.abs(b[1] - b[0]);
        e = @elementSize[a[2]];
        if (c && b[1] < c - 2 * d)
        {
            # если диапазон меньше чем один из ползунков,
            # убираем его.. (граничные случаи)
            b[1] = 0;
        }
        else if (b[1] > e - 2 * d)
        {
            # диапазон не должен выходить за пределы шкалы
            b[0] = d;
            b[1] = e - 2 * d;
        }
        b[2] = d;
        d = {};
        d[a[0]] = @_cssValue(b[0], e);
        d[a[1]] = @_cssValue(b[1], e);
        ##
        # 2. на фиксированной оси
        # определяем наименьший внутренний размер
        a.reverse!
        e = @elementSize[a[2]];
        c = @_rangeMap.map(function(val, index) {
            # шкала || ползунок
            return (val < 0) ? e : @handleSize[val][a[2]];
        }, this);
        c[1] = Math.min(c[0], c[1], e);
        # определяем смещение (центровка)
        c[0] = c[1] < e ?  (e / 2 - c[1] / 2) : 0;
        # сохраняем
        d[a[0]] = @_cssValue(c[0], e);
        d[a[1]] = @_cssValue(c[1], e);
        ##
        # кривизна границ
        c[2] = "";
        if (@options.round) {
            if (@options.round > 1)
            {
                # полное скругление
                c[2] = @_cssValue(c[1] / 2);
            }
            else if (b[2] < e)
            {
                # скругление в случае когда прямоугольный ползунок
                # входит в зону скругления шкалы
                # вычислим радиус
                e = e / 2;
                e = (e - b[2]) / e;# относительное значение
                e = (c[1] / 2) * e;# абсолютное
                c[2] = @_cssValue(e);
                # дополнительный радиус,
                # когда радиус на шкале становится меньше радиуса
                # на фиксированной оси (NEW syntax, future support?)
                if (b[1] / 2 < e) {
                    c[2] = c[2] + " / " + @_cssValue(b[1] / 2);
                }
            }
        }
        d["border-radius"] = c[2];
        # позиционируем
        @_range.css(d);
        return true;
    },
    # }}}
    # UTILITY
    _getHandleOffset: function(index) { # {{{
        var a, b, c, d;
        ##
        # подготовка
        if (index === 0)
        {
            a = @min;
            b = @max;
        }
        else
        {
            a = @_valueMin(index);
            b = @_valueMax(index);
        }
        # определяем значение
        c = @val[index];
        # +margin
        # корректируем
        if ((d = @options.margin) && !(index & 1))
        {
            c = c + d;
            a = a + d;
        }
        # определяем относительное значение
        c = a === b ? 1 : (c - a) / (b - a);
        # определим размер виртуальной шкалы
        b = @_getScaleSize(index);
        # определим позицию на виртуальной шкале
        # инвертируем значение в случае вертикального слайдера
        c = c * b[1];
        @orientation && (c = b[1] - c);
        # центрируем ползунок относительно позиции
        a = @handleSize[index];
        c = c - (@orientation ? a.height : a.width) / 2;
        # возврат
        return c + b[0];
    },
    # }}}
    _getScaleSize: function(index, virtual) { # scale size and offset {{{
        var a, b, c, d, e;
        ##
        # виртуальная шкала привязана к конкретному ползунку
        # в зависимости от ориентации слайдера
        a = @orientation ?
            ["height", "top", "h"] :
            ["width", "left", "w"];
        # определим размер шкалы
        e = @elementSize[a[2]];
        if (index > 0 || virtual)
        {
            # виртуальная шкала (шкала отдельного ползунка)
            # #1
            # предыдущий элемент, начальное смещение
            c = index - 1;
            if (c < 0)
            {
                b = @orientation ? e : 0;
            }
            else
            {
                # соседний ползунок
                b = @handleOffset[c][a[1]];
                # корректируем
                if (!@orientation) {
                    if (@options.strict) {
                        b = b + @handleSize[c][a[0]];
                    }
                    else {
                        b = b + @handleSize[c][a[0]] / 2;
                    }
                }
                else if (!@options.strict) {
                    b = b + @handleSize[c][a[0]] / 2;
                }
            }
            # #2
            # определим конечное смещение
            c = index + 1;
            if (c >= @val.length) {
                d = @orientation ? 0 : e;
            }
            else
            {
                # соседний ползунок
                d = @handleOffset[c][a[1]];
                # корректируем
                if (@orientation)
                {
                    if (@options.strict) {
                        d = d + @handleSize[c][a[0]];
                    }
                    else {
                        d = d + @handleSize[c][a[0]] / 2;
                    }
                }
                else if (!@options.strict) {
                    d = d + @handleSize[c][a[0]] / 2;
                }
            }
            # инвертируем значения для вертикального слайдера
            if (@orientation) {
                a[3] = d, d = b, b = a[3];
            }
        }
        else
        {
            # вся шкала
            # только для первого элемента
            b = 0;
            d = e;
            if (@options.strict)
            {
                # определяем размер остальных ползунков
                # не учитываем их на шкале
                for (c = 1; c < @val.length; c++) {
                    b += @handleSize[c][a[0]];
                }
                !@orientation && (d = d - b, b = 0);
            }
        }
        if (@options.strict)
        {
            # точный слайдер сдвигает ползунки внутрь шкалы
            a = @handleSize[index][a[0]] / 2.0;
            b = b + a;
            d = d - a;
        }
        # возврат [начало, размер шкалы, конец]
        return [b, d - b, d];
    },
    # }}}
    _getClosestHandle: function(coords) { # {{{
        var a, b, c, d;
        ##
        # определяем ближайший ползунок
        # при слайдинге, выбираем перетаскиваемый
        if (@_capture) {
            return @_handleIndex;
        }
        # возвращаем индекс единственного ползунка
        if (@val.length < 2) {
            return 0;
        }
        # подготовка
        # в зависимости от ориентации слайдера
        a = @orientation ?
            [coords.y - @elementOffset.top,  "height", "top", @elementSize.h, 0] :
            [coords.x - @elementOffset.left, "width", "left", @elementSize.w, 0];
        # для каждого ползунка
        for (b = 0; b < @val.length; b++)
        {
            # определяем его центр
            c = @handleOffset[b][a[2]] + @handleSize[b][a[1]] / 2.0;
            # определяем расстояние до центра
            if ((d = Math.abs(c - a[0])) < a[3])
            {
                # найден ближайший ползунок
                a[3] = d;
                a[4] = b;
            }
            else if (Math.abs(d - a[3]) < 0.0001)
            {
                # ползунки находятся в одной позиции,
                # определяем положение относительно этой позиции
                if (!@orientation && a[0] - c >= 0)
                {
                    # выбираем ползунок справа
                    a[3] = d;
                    a[4] = b;
                }
                else if (@orientation && a[0] - c < 0)
                {
                    # выбираем ползунок сверху
                    a[3] = d;
                    a[4] = b;
                }
            }
        }
        return a[4];
    },
    # }}}
    _valueMin: function(index) { # {{{
        if (@val.length < 2 || !index) {
            return @min;
        }
        return @val[index - 1] + @options.margin;
    },
    # }}}
    _valueMax: function(index) { # {{{
        if (@val.length < 2 ||
            index === undefined ||
            index + 1 >= @val.length)
        {
            return @max;
        }
        return @val[index + 1] - @options.margin;
    },
    # }}}
valRefine: (val, outside) -> # {{{
    # prepare
    d = @data
    o = @options
    # single value
    if typeof! val != "Array"
        # apply reversed
        val = d.max - val + d.min if d.reversed
        # apply shift
        val = val + d.shift if d.shift and outside
        # trim
        return @valTrim val
    # multiple values
    # sync length
    while val.length < d.val.length
        val.push @valRefine d.max, outside
    # fix
    if outside
        # value is from outside world
        # apply shift and reversed
        val = val + d.shift if d.shift and outside
        d.reversed and val = val.map (val) ->
            d.max - val + d.min;
    else
        # на вход
        val = val.map(function(val, index) {
            # только целые числа в ограниченном диапазоне
            val = @_valueTrim(val, index, true, true);
            # инвертируем значение
            return a ? (@max - val + @min) : val;
        }, this).sort(function(e1, e2) {
            # сортировка по возрастанию
            return e1 < e2 ? -1 : 1;
        });
        (a = @options.margin) && (val = val.map(function(val, index, arr) {
            # корректируем значение в соответствии с отступом
            # определяем диапазон
            b = jQuery.inArray(index, @_rangeMap);
            # отступ привязан к начальному ползунку диапазонa
            if (b >= 0 && !(b & 1) && (c = @_rangeMap[b + 1]) > 0 &&
                arr[c] - a < val) # отступ нарушен
            {
                # корректировка
                # отталкиваемся от верхней границы
                val = arr[c] - a;
                if (val <= @min)
                {
                    # на дне, поднимаем верхнюю границу
                    val = @min;
                    d = val + a;
                    arr[c] = d > @max ? @max : d;
                }
            }
            return val;
        }, this));
    }
    return val;
    # ..
    true
# }}}
valTrim: (val, index, noMargin, forceStep) -> # {{{
    # returns the closest +step+margin-aligned value
    ##
    # подготовка
    forceStep = (forceStep && index !== undefined);
    # определим минимум и максимум
    a = [@min, @max, @min, @max];
    b = @val.length;
    c = 0;
    if (arguments.length > 1 && (b = @val.length) > 1)
    {
        # для нескольких ползунков,
        # границами являются соседние, но если задан флаг форсирования шага,
        # значение должно быть выравнено - упользуются границы min/max.
        if (!forceStep)
        {
            if (index > 0) {
                a[0] = @val[index - 1];
            }
            if (index < b - 1) {
                a[1] = @val[index + 1];
            }
        }
        # учитываем +margin
        if ((c = @options.margin) && (d = jQuery.inArray(index, @_rangeMap)) >= 0)
        {
            # в зависимости от четности/нечетности,
            # добавляем ограничение
            if (d & 1) {
                a[2] = a[0] + c;
            }
            else {
                a[3] = a[1] - c;
            }
        }
    }
    # проверка выхода за границы
    if (val < a[2]) {
        return a[2];
    }
    if (val > a[3]) {
        return a[3];
    }
    # корректируем значение
    if (@step)
    {
        # определим размер шага
        d = (@max - @min) / @step;
        d <= 1 && (d = 1);
        # приближаемся к значению
        for (b = @min; b + d <= val; b += d);
        b = [b, b + d];
        # определим ближайшее
        d = [Math.abs(val - b[0]), Math.abs(val - b[1])];
        if (d[0] !== d[1])
        {
            # найдено
            val = d[0] < d[1] ? b[0] : b[1];
        }
        else
        {
            # оба приближения равноудалены,
            # выбираем ближаешее к границе
            d = [b[0] - a[0], a[1] - b[1]];
            if (d[0] !== d[1])
            {
                # найдено
                val = d[0] < d[1] ? b[0] : b[1];
            }
            else if (forceStep)
            {
                # по центру,
                # определим ближайшее к текущему
                return @val[index] <= b[0] ? b[0] : b[1];
            }
            else
            {
                # по центру,
                # возвращаем как есть
                return val;
            }
        }
        # проверим выход за границы
        if (noMargin)
        {
            val > a[1] && (val = a[1]);
            val < a[0] && (val = a[0]);
        }
        else
        {
            val > a[3] && (val = a[3]);
            val < a[2] && (val = a[2]);
        }
    }
    return Math.round(val);
},
# }}}
/** }}} **/
/**** }}} */
}
false and w3ui.sensor = {
    /* {{{
    * TODO:
    */
    options: # {{{
        empty: true
    # }}}
    data: # {{{
        target: []              # DOM targets
        sensor: []              # target sensors
        event:  []              # event handlers
        state: null             # element state
    # }}}
    ###
    create: -> # {{{
        # prepare
        me = @
        d = @data
        @refresh!
        # put sensors into the DOM
        @scan!forEach (node) -> me.add node
        # attach event handlers
        for a,b in d.sensor
            a.0.addEventListener "scroll", d.event[b]
            a.2.addEventListener "scroll", d.event[b]
            @recharge b
        # done
        true
    # }}}
    destroy: !-> # {{{
        # prepare
        d = @data
        # remove listeners
        for a,b in d.sensor
            # detach events handlers
            a.0.removeEventListener "scroll", d.event[b]
            a.2.removeEventListener "scroll", d.event[b]
            # check sensor link count
            c = a.data d.class
            if not c or c == 1
                # no more listeners,
                # remove sensor from the DOM
                a.remove!
            else
                # decrease counter
                a.data d.class, c - 1
        # clear data
        d.target.length = 0
        d.sensor.length = 0
        d.event.length  = 0
    # }}}
    attach: -> # {{{
        true
    # }}}
    detach: -> # {{{
        true
    # }}}
    event: (handler, event) -> # {{{
        # check
        if @options.disabled or @core.options.disabled
            event.stopPropagation!
            event.preventDefault!
            return false
        # call handler
        if a = @[handler] event
            # event handled
            event.stopImmediatePropagation! # dont call others
            event.stopPropagation! # dont bubble
            event.preventDefault! # dont do the defaults
        # result
        a
    # }}}
    ###
    /*
    refresh: !-> # {{{
        # prepare
        a = @element.0
        a =
            [a.offsetLeft, a.offsetTop]
            [a.offsetWidth, a.offsetHeight]
            [a.scrollLeft, a.scrollTop]
        # fix
        a.0.map (val) ->
            if val == null then 0 else val
        # store
        @data.state = a
    # }}}
    scan: -> # {{{
        # prepare
        me = @
        d  = @data
        # collect parents
        a = @element.parents!get!
        # add self
        a.push @element
        return a if a.length == 1
        # limit parents to document's body
        if (b = a.indexOf document.body) > 0
            a = a.slice 0, b - 1
        # prepare filter
        b =
            display:  [\block \flex]
            position: [\static \relative]
        # collect children of each parent container
        # take only those which may affect
        # size and offset (declared first)
        c = @element # first stop element
        for parent in a.slice!
            for node,index in parent.children
                # cancel at stop element
                break if node == c
                # check node
                # get styles in array
                d = $ node .css b.keys! .entries!
                # it must be a realative block container
                d = d.every (node) ->
                    b[node.0] and b[node.0].includes node.1
                # store
                a.push node if d
            # set next stop
            c = parent
        # result
        a
    # }}}
    add: (node) !-> # {{{
        # prepare
        me = @
        d  = @data
        # check if already added
        return if d.target.includes node
        # search sensor
        c = $ node
        if (a = c.children "." + d.class).length == 0
            # sensor not found
            # create DOM node
            a = document.createElement "div"
            a.className = d.class
            b = "position:absolute;left:0;top:0;"
            a.style.cssText = b +
                "right:0;bottom:0;" +
                "overflow:hidden;z-index:-1;visibility:hidden;opacity:0;"
            a.innerHTML =
                "<div style='" + a.style.cssText + "'><div style='" + b + "'></div></div>" +
                "<div style='" + b + "width:200%;height:200%;'></div>"
            # store in target container
            c.append a
            # switch container position to relative
            b = \position
            c.css b, \relative if c.css b == \static
            # define sensor nodes
            a = $ a
            b = a.0
            a.add [
                # shrink
                b.children.1
                # expand
                b.children.0
                b.children.0.children.0
            ]
        # sensor found
        # increment listener count
        b = 0 if not b = a.data d.class
        a.data d.class, b + 1
        # save
        b = d.sensor.length
        d.target[b] = node
        d.sensor[b] = a
        d.event[b]  = @event.bind @, b
        true
    # }}}
    event: (index, event) -> # target scroll {{{
        # prepare
        d = @data
        s = d.state
        # event handled
        event.stopPropagation!
        event.preventDefault!
        # update state
        @refresh!
        @recharge index
        # dont call api if disabled
        return true if @options.disabled
        # check for change
        a = s.map (lst, a) ->
            lst.some (val, b) ->
                (Math.abs val - s[a][b]) > 0.00001
        # no changes, quit
        return true if a.every (val) -> val == false
        # callback
        @api.offset.apply @core, a[0] if a[0]
        @api.resize.apply @core, a[1] if a[1]
        @api.scroll.apply @core, a[2] if a[2]
        true
    # }}}
    recharge: (index) !-> # {{{
        # prepare
        return if not a = @data.sensor[index]
        # reset
        b = 10000
        a[0].scrollLeft   = b
        a[0].scrollTop    = b
        a[2].scrollLeft   = b
        a[2].scrollTop    = b
        a[3].style.width  = b + "px"
        a[3].style.height = b + "px"
    # }}}
    */
    ###
    api: # {{{
        offset: (x, y) !->      # offset change
        resize: (x, y) !->      # size change
        scroll: (x, y) !->      # scroll change
    # }}}
/**** }}} */
}


# vim: set et ts=4 sw=4 sts=4 fdm=marker fenc=utf-8 ff=dos:
