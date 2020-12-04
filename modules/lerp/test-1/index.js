(function() {
    var count = 0;
    var video = document.querySelectorAll('.minimizable')[0];
    var box   = document.querySelectorAll('.box')[0];
    ////
    ////
    video.addEventListener('click', function() {
        var a, b;
        ////
        // create timeline
        a = new TimelineLite({paused: true});
        // determine container
        // offsets and size
        b = box.getBoundingClientRect();
        // set detach area parameters
        a.set(box, {
            css: {
                '--x-top': b.top+'px',
                '--x-bottom': b.bottom+'px',
                '--x-left': b.left+'px',
                '--x-right': b.right+'px',
                '--x-width': b.width+'px',
                '--x-height': b.height+'px'
            }
        });
        // check state
        if (count++ % 2)
        {
            // ATTACH
            ////
            a.to(video, 1, {
                className: '>minimized',
                ease: Power3.easeIn
            });
            a.set([box, video], {
                className: '>detached'
            });
        }
        else
        {
            // DETACH
            ////
            a.set([box, video], {
                className: '<detached'
            });
            a.to(video, 1, {
                className: '<minimized',
                ease: Power3.easeOut
            });
        }
        a.play();
    });
})();
