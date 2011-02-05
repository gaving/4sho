// ==UserScript==
// @name           4sho
// @namespace      4sho
// @description    4sho
// @include        http://boards.4chan.org/*
// @require        http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js
// ==/UserScript==

var css = (<r><![CDATA[
      .ribbon {
        background-color: #a00;
        overflow: hidden;
        position: absolute;
        right: 0em;
        top: 2.5em;
        -moz-transform: rotate(+45deg);
        -webkit-transform: rotate(+45deg);
        -moz-box-shadow: 0 0 1em #888;
        -webkit-box-shadow: 0 0 1em #888;
      }
      .ribbon a {
        border: 1px solid #faa;
        color: #fff;
        display: block;
        font: bold 81.25% 'Helvetiva Neue', Helvetica, Arial, sans-serif;
        margin: 0.05em 0 0.075em 0;
        padding: 0.5em 3.5em;
        text-align: center;
        text-decoration: none;
        text-shadow: 0 0 0.5em #444;
      }
]]></r>).toString();

(function() {

    var $reply = $("a:contains('Reply')");
    var location = window.location.href.replace('http', 'boxy');

    if ($reply.length) {
        $reply
            .parent()
            .append(
                $('<a/>').addClass('x').text('[4sho]')
                .css({ 'color': '#FFF', 'background': '#3F4C6B'})
            );

        $('a.x').each(function() {
            $(this).attr({
                'href' : location + $(this).prev().attr('href')
            });
        });
    } else {
        $('head').append($('<style/>').attr({ type: 'text/css' }).append(css));
        $('body').append(
            $('<div/>').addClass('ribbon').append($('<a/>').attr({ href: location }).text("4sho'"))
        );
    }
})();
