// Generated by LiveScript 1.6.0
"use strict";
var imageUploader, toString$ = {}.toString;
imageUploader = function(){
  var hereDoc, htmlToElement, store, template, api, Item, Data;
  hereDoc = function(f){
    var a, b;
    f = f.toString();
    a = f.indexOf('/*');
    b = f.lastIndexOf('*/');
    return f.substring(a + 2, b - 1).trim();
  };
  htmlToElement = function(){
    var temp;
    temp = document.createElement('template');
    return function(html){
      temp.innerHTML = html;
      return temp.content.firstChild;
    };
  }();
  store = new WeakMap();
  template = {
    svgAdd: hereDoc(function(){
      /*
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
      	<circle class="e1" cx="50" cy="50" r="49"/>
      	<circle class="e2" cx="50" cy="50" r="46"/>
      	<path class="e3" d="M64 17c0-1-1-2-2-2H38c-1 0-2 1-2 2v19H17c-1 0-2 1-2 2v24c0 1 1 2 2 2h19v19c0 1 1 2 2 2h24c1 0 2-1 2-2V64h19c1 0 2-1 2-2V38c0-1-1-2-2-2H64V17z"/>
      	<path class="e4" d="M81 60H62c-1 0-2 1-2 2v19H40V62c0-1-1-2-2-2H19V40h19c1 0 2-1 2-2V19h20v19c0 1 1 2 2 2h19v20z"/>
      </svg>
      */
    }),
    svgRemove: hereDoc(function(){
      /*
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
      	<circle style="stroke: black; fill: white;" cx="50" cy="50" r="49"/>
      	<circle style="stroke:none; fill:white;" cx="50" cy="50" r="46"/>
      	<path style="stroke:none; fill:red;" d="M36 16c-1-1-2-1-3 0L16 33c-1 1-1 2 0 3l14 14-14 14c-1 1-1 2 0 3l17 17c1 1 2 1 3 0l14-14 14 14c1 1 2 1 3 0l17-17c1-1 1-2 0-3L70 50l14-14c1-1 1-2 0-3L67 16c-1-1-2-1-3 0L50 30 36 16z"/>
      	<path style="stroke:none; fill:none;" d="M79 35L65 49c-1 1-1 2 0 3l14 14-14 14-14-14c-1-1-2-1-3 0L34 80 20 66l14-14c1-1 1-2 0-3L20 35l14-14 14 14c1 1 2 1 3 0l14-14 14 14z"/>
      </svg>
      */
    }),
    item: hereDoc(function(){
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
    }),
    upload: hereDoc(function(){
      /*
      <div class="upload">
      	<div class="box">{{svgAdd}}</div>
      </div>
      */
    })
  };
  api = {
    get: function(data, k){
      switch (k) {
      case 'type':
        return 'w3ui-image-uploader';
      case 'readonly':
      case 'readOnly':
        return data.readonly;
      case 'value':
        return data.getMetadata();
      }
      return null;
    },
    set: function(data, k, v){
      switch (k) {
      case 'readonly':
      case 'readOnly':
        data.setReadonly(!!v);
        break;
      case 'value':
        if (toString$.call(v).slice(8, -1) === 'Array') {
          return data.setItems(v);
        }
      }
      return true;
    }
  };
  Item = function(data, index, src){
    var a, b;
    a = template.item.replace(/{{svgRemove}}/g, template.svgRemove);
    this.node = htmlToElement(a);
    this.index = index;
    this.src = src;
    this.preview = this.node.children[0].children[0];
    this.remover = this.node.children[1].children[0];
    this.remove = this.remove(data);
    this.image = this.preview.children[0];
    this.input = null;
    this.detached = false;
    if (src) {
      a = this.image;
      a.src = data.srcBase + src;
      a.alt = '';
    } else {
      this.input = a = document.createElement('input');
      if (b = data.name) {
        a.name = b + '[]';
      }
      a.type = 'file';
      a.accept = 'image/*';
      a.addEventListener('input', this.inject(data));
    }
    this.preview.addEventListener('click', this.open(data));
    this.remover.addEventListener('click', this.remove);
  };
  Item.prototype = {
    open: function(data){
      var this$ = this;
      return function(){
        if (this$.detached) {
          this$.preview.classList.remove('detached');
          this$.detached = false;
        } else {
          this$.preview.classList.add('detached');
          this$.detached = true;
        }
      };
    },
    remove: function(data){
      var this$ = this;
      return function(force){
        var a;
        if (force || !data.readonly) {
          this$.node.remove();
          a = data.items.indexOf(this$);
          data.items.splice(a, 1);
          --data.count;
          while (a < data.count) {
            --data.items[a].index;
            ++a;
          }
          if (!data.readonly) {
            a = data.upload.classList;
            if (data.count < data.limit && !a.contains('enabled')) {
              a.add('enabled');
            }
          }
        }
      };
    },
    inject: function(data){
      var this$ = this;
      return function(e){
        var a, b;
        if (!(a = this$.input.files) || !a.length) {
          return;
        }
        this$.src = a = a[0];
        if (!a.type.startsWith('image/')) {
          return;
        }
        b = this$.image;
        b.alt = a.name;
        b.src = window.URL.createObjectURL(a);
        b.addEventListener('load', function(){
          window.URL.revokeObjectURL(this$.image.src);
        });
        if (this$.index === data.count) {
          data.items[data.count] = this$;
          data.node.insertBefore(this$.node, data.upload);
        } else {
          a = this$.index;
          b = data.items[a];
          while (++a <= data.count) {
            data.items[a] = data.items[a - 1];
          }
          data.items[this$.index] = this$;
          data.node.insertBefore(this$.node, b.node);
        }
        this$.node.appendChild(this$.input);
        if (++data.count >= data.limit) {
          data.upload.classList.remove('enabled');
        }
      };
    }
  };
  Data = function(node, opts){
    var upload, this$ = this;
    this.node = node;
    this.srcBase = opts.srcBase || '';
    this.name = opts.name || '';
    this.limit = opts.limit || 4;
    this.readonly = !!opts.readonly;
    this.maxSize = opts.maxSize || 0;
    this.items = [];
    this.itemsIn = [];
    this.count = 0;
    this.upload = upload = htmlToElement(template.upload.replace(/{{svgAdd}}/g, template.svgAdd));
    if (!this.name && node.hasAttribute('name')) {
      this.name = node.getAttribute('name');
    }
    node.innerHTML = '';
    if (this.readonly) {
      node.className += ' readonly';
    }
    node.appendChild(upload);
    if (opts.items) {
      this.setItems(opts.items);
    } else {
      this.setItems([]);
    }
    upload.children[0].addEventListener('click', function(e){
      var a;
      e.preventDefault();
      e.stopPropagation();
      if (!this$.readonly && this$.count < this$.limit) {
        a = new Item(this$, this$.count, '');
        a.input.click();
      }
    });
  };
  Data.prototype = {
    getMetadata: function(){
      var F, A, R, O, a, i$, ref$, len$, b;
      F = {
        length: 0
      };
      A = [];
      R = null;
      O = null;
      a = this.items;
      a = 0;
      for (i$ = 0, len$ = (ref$ = this.items).length; i$ < len$; ++i$) {
        b = ref$[i$];
        if (b.input) {
          A[a] = b.index;
          F[a] = b.src;
          ++a;
        }
      }
      F.length = a;
      for (i$ = 0, len$ = (ref$ = this.itemsIn).length; i$ < len$; ++i$) {
        b = i$;
        a = ref$[i$];
        if (this.items.indexOf(a) === -1) {
          if (!R) {
            R = [];
          }
          R[R.length] = b;
        } else if (a.index !== b) {
          if (!O) {
            O = {};
          }
          O[b] = a.index;
        }
      }
      if (!F.length && !R && !O) {
        return null;
      }
      if (F.length) {
        F.add = A;
      }
      if (R) {
        F.remove = R;
      }
      if (O) {
        F.order = O;
      }
      return F;
    },
    setItems: function(items){
      var a, b;
      while (this.count) {
        this.items[0].remove(true);
      }
      if ((this.count = items.length) > this.limit) {
        this.count = this.limit;
      }
      a = -1;
      while (++a < this.count) {
        this.items[a] = b = new Item(this, a, items[a]);
        this.node.insertBefore(b.node, this.upload);
      }
      this.itemsIn = this.items.slice();
      if (!this.readonly && this.count < this.limit) {
        this.upload.classList.add('enabled');
      }
      return true;
    },
    setReadonly: function(flag){
      if (this.readonly !== flag) {
        if (this.readonly = flag) {
          this.node.classList.add('readonly');
          this.upload.classList.remove('enabled');
        } else {
          this.node.classList.remove('readonly');
          if (this.count < this.limit) {
            this.upload.classList.add('enabled');
          }
        }
      }
    }
  };
  return function(node, opts){
    var x;
    if (!opts) {
      return store.has(node) ? store.get(node) : null;
    }
    x = new Proxy(new Data(node, opts), api);
    store.set(node, x);
    return x;
  };
}();
/***/