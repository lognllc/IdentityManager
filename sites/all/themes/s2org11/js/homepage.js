$(function() {
    $('.homepage .video').click(function() {
        $('.homepage .video .iframe').append('<iframe width="456" height="252" src="http://www.youtube.com/embed/CkjRvBMwzo4?fs=1&autoplay=1&loop=1&version=3&autohide=1&showinfo=0" frameborder="0" allowfullscreen></iframe>');
        $('.homepage .video .iframe').fadeIn(700);
        $('.homepage .video img').fadeOut(700);
    });
})
var i = 0;
(function featuredOn() {
    $('.homepage .extra .press a img').eq(i%8).fadeOut('slow', function() {
        $('.homepage .extra .press a img').eq(++i%8).fadeIn();
        setTimeout(featuredOn, 3000);
    });
})();