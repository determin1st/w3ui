var box = document.querySelectorAll(".box");
var el = document.querySelectorAll(".el");
el[0].addEventListener("click", startTest.bind(null, el[0], box[0]));
el[1].addEventListener("click", startTestManual.bind(null, el[1], box[1]));
el[2].addEventListener("click", startTestMod.bind(null, el[2], box[2]));


function startTest(el, box) {
  var a, b;
  // check state
  if (el.classList.contains("clicked")) {
    b = "-=clicked";
  } else {
    b = "+=clicked";
  }
  // animate
  a = new TimelineLite({
    paused: true
  });
  a.to(box, 1, {
    className: b,
    ease: Power3.easeInOut
  });
  a.to(el, 1, {
    className: b,
    ease: Power3.easeInOut
  }, 0);
  a.play();
}


function startTestManual(el, box) {
  var a, b;
  // check state
  b = !!startTestManual.state;
  // change state
  startTestManual.state = !startTestManual.state;
  // animate
  a = new TimelineLite({
    paused: true
  });
  if (!b)
  {
    a.to(box, 1, {
      padding: 0,
      ease: Power3.easeInOut
    });
    a.to(el, 1, {
      height: '300px',
      padding: 0,
      ease: Power3.easeInOut
    }, 0);
  }
  else
  {
    a.to(box, 1, {
      padding: '4px',
      ease: Power3.easeInOut
    });
    a.to(el, 1, {
      height: '50px',
      padding: '20px',
      ease: Power3.easeInOut
    }, 0);
  }
  a.play();
}


function startTestMod(el, box) {
  var a, b;
  // check state
  if (el.classList.contains("clicked")) {
    b = ">clicked";
  } else {
    b = "<clicked";
  }
  // animate
  a = new TimelineLite({
    paused: true
  });
  a.to(box, 1, {
    className: b,
    ease: Power3.easeInOut
  });
  a.to(el, 1, {
    className: b,
    ease: Power3.easeInOut
  }, 0);
  a.play();
}


