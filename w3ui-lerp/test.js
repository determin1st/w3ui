// prepare environment
// define constructor and dynamic methods
var Something = function() {
    this.prop1  = 1;
    this.prop2  = 2;
    this.result = 0;
    this.flag   = false
    this.method = null;
}
var method1 = function() {
    this.result = Math.random() * this.prop1 + this.prop2;
}
var method2 = function() {
    this.result = this.prop1 * this.prop2 + Math.random();
}

// create storage
var a = [];

// fill storage with objects of the same hidden class
// but different methods selected randomly
var i,j,k = 100;
for (i = 0; i < k; ++i) {
    a[i] = j = new Something();
    if (Math.random() > 0.8) {
        j.method = method1;
    }
    else {
        j.method = method2;
        j.flag = true;
    }
}
// done



for (i = 0; i < k; ++i)
{
  if (a[i].flag) {
    a[i].method();
  }
  else {
    a[i].method();
  }
}
for (i = 0; i < k; ++i) {
    a[i].method();
}



