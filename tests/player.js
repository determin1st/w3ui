"use strict";

var test = async function() {
    ///
    // check requirements
    if (typeof w3ui === 'undefined') {
        return;
    }
    ///
    // check dependencies
    if (!(await w3ui.load(['player']))) {
        return;
    }
    // prepare controls
    var btn = [...document.querySelectorAll('button')];
    var canvas = document.querySelector('canvas');
    ///
    // create a video player
    var player = w3ui.player(canvas, {
        ///
        // required options
        base: '',           // base path to the stream source (httpFetch)
        ///
        // track options
        autoplay: false,    // whether to start playing after the load
        autopause: true,    // whether to pause playback when the tab is inactive
        autoloop: false,    // whether to loop the video in the end (static files only)
        volume: 1,          // initial volume
        bufferSize: 0
    });
    // set event handlers
    btn[0].addEventListener('click', async function(e) {
        ///
        // load new video/audio track
        if (await player.load('resource'))
        {
        }
    });
    btn[1].addEventListener('click', async function(e) {
        player.play();
    });
    btn[2].addEventListener('click', async function(e) {
        player.pause();
    });
    /***/
    // HELPERS {{{
    var lockButtons = function(isStream)
    {
    };
    var unlockButtons = function()
    {
        btn.forEach(function(b) {
            b.disabled = false;
        });
    };
    // }}}
    /***/
    unlockButtons();
};
