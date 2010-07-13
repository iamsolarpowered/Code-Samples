// Copyright 2010 Ben Shymkiw

// Only hide if JS is enabled
document.write(
  "<style type='text/css'>"
  + "#main, #github_ribbon { display: none; }"
  + "</style>"
);

$(document).ready(function() {

  // Put your best foot forward
  $('.post').fadeTo(500, 0.5);   
  $('#main').delay(2000).slideDown(1000);
  $('#github_ribbon').delay(4000).fadeTo(0, 0.7).animate({top: 0}, 750);
  
  $('#background .in').animate({height: 370}, 1000, 'swing');
  
  // Do something cool to show you're paying attention
  $('.post').hover(function() {
    $(this).fadeTo(500, 1.0);
  }, function() {
    $(this).fadeTo(250, 0.5);
  });
  
  // Make sure they know who you are
  $(window).scroll(function() {
    var push_down = $(window).scrollTop() - 206;
    if(push_down < 0) { push_down = 0};
    $('#sidebar').css('top', push_down+'px');
  });
  
  // Help 'em pick the right page
  $('.pagination a').hover(function() {
    var content = $(this).html();
    $(this).attr('title', content);
  });
  
  // Open external links in new window and track with Google Analytics
  $('a').click(function() {
    url = $(this).attr('href');
    if(!url.match(location.host) && !url.match(/(^\/)|(^#)/)) {
      $(this).attr('target', '_blank');
      pageTracker._trackPageview('/external/' + url);
    }
  });
  
});
