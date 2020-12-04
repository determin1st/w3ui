# w3ui
*Individual [asynchrony](https://en.wikipedia.org/wiki/Asynchrony_(computer_programming))
[Web UI](https://developer.mozilla.org/en-US/docs/Web/Web_Components)
wrapper for [the browser](https://en.wikipedia.org/wiki/Web_browser)
([experimental](https://developer.mozilla.org/en-US/docs/MDN/Contribute/Guidelines/Conventions_definitions#Experimental))*
<details>
  <summary>mission briefing</summary>

  Welcome back, **Dom**trooper!

  This is your **first** fieldwork, but it should be treated as a **real mission**.
  No easy-going moves and no retreats - it will be **considered** as a failure.
  If it fails here - there is no **path** for you **to the frontiers**.

  Take your **w3ui kit** and let's start..

  The dropzone to the **web platform** swarms with different specs,
  which are **not freindly**. Some of them may be helpful, though.
  **w3ui gears** does not protect you against simple creatures,
  use your own survival skills and **move quickly** with w3ui modules.

  The first module to load is a streamgun **httpFetch**5000,
  which is re-assebled from **the web** spider beast.

  After you establish **interconnections** with the self-origin,
  try to complete extra quest to the remote server.

  Down to up approach
</details>

[![The Domguy](https://raw.githack.com/determin1st/w3ui/master/tests/logo.jpg)](http://www.nathanandersonart.com/)


## Tests
- [**player**](http://raw.githack.com/determin1st/w3ui/master/tests/player.html): mpeg1 video player

## Fluent
(link)

## Where is the Doc?
<details>
  <summary>MIA</summary>

  There is a bunch of options about stuff which goes in and goes out.
  To assemble all that, the proper [reference manual](https://en.wikipedia.org/wiki/Documentation)
  (similar or better than done by [Spider Mastermind](https://github.com/determin1st/httpFetch))
  should been written. But the thing is different here,
  the most code itself is a set of [widget components](https://en.wikipedia.org/wiki/Graphical_widget)
  sitting there as [ES6 modules](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules).
  One widget - one module. Any module gains full control over the browser.
  There is no implicit [heirarchy](https://en.wikipedia.org/wiki/Hierarchy),
  but modules may depend on each other.
  All, the **w3ui** does is loading and aggregating ([importing](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/import))
  those modules. This happens in the background ([asynchronous IIFE](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function))
  as it will improve load times ([the faith is strong](https://en.wikipedia.org/wiki/Asynchronous_I/O)).
  The module exports itself (`export default`) into [w3ui context](https://developer.mozilla.org/en-US/docs/Glossary/Scope)
  and gets exposed via [w3ui proxy](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy/handler).
  Module is either resolved to null (when fails) or
  to a feasible api (mostly the [proxy objects](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy))
  which provide module's features.

  The module's code type is javascript (.js)
  placed in a file in `modules` directory, named as `some-module-name.js`.
  Upon loading it becomes accessible with `w3ui.someModuleName`.
  That way, modules are restricted without any force.
  Userland code is only responsible for interconnection with w3ui and
  application of the module features.

  Module's code follow KISS principle,
  it's both [self-documenting](https://en.wikipedia.org/wiki/Self-documenting_code)
  and [packed with comments](https://en.wikipedia.org/wiki/Literate_programming).
  Also, it has special markers for [fold navigation](https://jdhao.github.io/2019/08/16/nvim_config_folding/).

  According to that, no more documentation required:
  - tests reproduce use-cases for general application.
  - code is a reference manual.

  (todo)(stop)
</details>


## The difference between library and framework
The wikipedia tells:
> A JavaScript framework is an application framework written in JavaScript. It differs from a JavaScript library in its control flow: A library offers functions to be called by its parent code, whereas a framework defines the entire application design. A developer does not call a framework; instead, the framework calls and uses the code in some particular way.

Quite a reasonable statement. Also, [check this quote](https://martinfowler.com/bliki/InversionOfControl.html):
> One important characteristic of a framework is that the methods defined by the user to tailor the framework will often be called from within the framework itself, rather than from the user's application code. 

How to determine the category where to put a particular thing, then?

Lets check **`React`**:
![React example 0](https://raw.githack.com/determin1st/w3ui/master/tests/react-is-this.jpg)
#### Is it a library?
Babel is quite a dull.. and it's chained with React (no more links here).
Let's compare the gist above with the official,
one-page html (unnecessary links/comments removed):
```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>Hello World</title>
    <script src="https://../react.development.js"></script>
    <script src="https://../react-dom.development.js"></script>
    <script src="https://../babel.min.js"></script>
  </head>
  <body>
    <div id="root"></div>
    <script type="text/babel">

      ReactDOM.render(
        <h1>Hello, world!</h1>,
        document.getElementById('root')
      );

    </script>
  </body>
</html>
```
The result is the same set of wrappers.
#### Who wraps who?
It's not **`React`**'s fault - it's **`Babel`**'s you may think,
but in this case, it brings even more fault with [implicit dependency](https://en.wikipedia.org/wiki/Dependency_hell).

Check out React docs, they are huge.. about, how to work inside that thing.
That's not how the library interaction goes.

The library usage may look like:
```javascript
$.ajax({
  url: "/api/getWeather",
  data: {
    zipcode: 97201
  },
  success: function( result ) {
    $( "#weather-temp" ).html( "<strong>" + result + "</strong> degrees" );
  }
});
```
See, valid javascript, not Babel. That's an jQuery's ajax, they promote it first,
because the library lost it's point in time after the native platform apis evolved.
Still, [a wrapper around HTTP request/response](https://github.com/determin1st/httpFetch)
is a good idea.
w3ui usage may look like:
```javascript
window.w3ui = await (await import('./w3ui/modules/w3ui.js')).default;
```
Quite unusual (useless/dumb), but it does everything explicitly (oh, really?),
what other libs or frameworks may hide (wat?). jQuery, for example,
does `window.$ = jQuery` - a propagation to the globals, just for another
name (shortcut). That's because jQuery's name isn't as cool as w3ui's name.
Also, in case of **`w3ui`** you may choice any name(s) for the globals.
The instance types are different. There may
be multiple jqueries around (different versions?),
but the **`w3ui`** forever stays singleton with detachable modules.
The `await await` stuff is fully related to the wierd experimental
specs WATWG produces. That's not **`w3ui`**'s fault -
That's how you do it according to the spec:

- fetching code with wacky `import` (dynamic import function)
- waiting it completes to so-called `Module` object
  (which is impossible to find in the [MDN doc](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules),
  but you can find a "Babel" word there)
- finally, doing `await` until `default` export resolves.
- and, seting a global (or maybe not)

There is also a "sugar way" to shorten this:
```html
<script src="w3ui/w3ui.js"></script>
```
But that's not the end..
#### The difference between sync and async library
Currently, that is the main thing between **w3ui** and **something**.

## So prepare, Domguy..
Either you want to be "safe" with frameworks,
or better, breathe fresh [web platform](https://developer.mozilla.org/en-US/docs/Web/API)
and risk with your own skill.




