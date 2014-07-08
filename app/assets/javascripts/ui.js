$(document).ready(main);           // fresh page loads
$(document).on('page:load', main); // cached page loads and turbolinks

function main() {
  handleSidebar();
  replaceSearchURL();
  handleSearchRequests();
  handlePageChanges();
}

function handleSidebar() {
  $('#sidebar').buildMbExtruder({
    positionFixed:true,
    width:250,
    sensibility:800,
    position:"left",
    extruderOpacity:1,
    flapDim:100,
    textOrientation:"bt",
    onExtOpen:function(){},
    onExtContentLoad:function(){},
    onExtClose:function(){},
    hidePanelsOnClose:true,
    autoCloseTime:0,
    slideTimer:300
  });
  $('.flap').click(function() {
    if ($.cookie('sidebar_enabled')) {
      $.removeCookie('sidebar_enabled');
    } else {
      $.cookie('sidebar_enabled', 'true');
    }
  });
  if ($.cookie('sidebar_enabled')) {
    setTimeout(function(){ $('#sidebar').openMbExtruder(true);}, 250);
  }
}

function replaceSearchURL() {
  history.replaceState(null, null, getData('path'))
}

function handleSearchRequests() {
  $('form').submit(function(e) {
    $.ajax({
      url: '/pages',
      type: 'POST',
      dataType: 'json',
      data: $(this).serialize(),
      success: function(results) {
        if (results['page'] == null) {
          showNoResultsAlert();
        } else {
          displayResults(results['page']);
          updatePreviousSearches(results['search_history']);
        }
      }
    })
    e.preventDefault();
  });
}

function showNoResultsAlert() {
  if ($('main .alert').length == 0) {
    $('main').prepend("\
      <div class='alert alert-danger'>\
        <button aria-hidden='true' class='close' data-dismiss='alert' type='button'>&times;</button>\
        <div id='flash_alert'>"+getData('nosearchresults-message')+"</div>\
      </div>\
    ");
  }
}

function displayResults(page_object) {
  var book = page_object['book'];
  var page = page_object['id'];
  history.replaceState(null, null, getData('path'));
  $('#page img.page').attr('src', getData('image-file'));
  $('#page a.left').attr('href', '/'+book+'/'+(page-1));
  $('#page a.right').attr('href', '/'+book+'/'+(page+1));
  $('div.alert.alert-danger').remove();
}

function updatePreviousSearches(search_history) {
  var html = '';
  for (var i in search_history) {
    word = search_history[i];
    html += "<a class='navbar-brand' href='/"+word+"'>"+word+"</a>";
  }
  $('#search_history').html(html);
}

function handlePageChanges() {
  var href, book, page, classes;
  $('#page a.page').click(function(e) {
    href = $(this).attr('href');
    book = getData('book');
    page = parseInt(href.split('/')[2]);
    classes = $(this).attr('class');
    // location und bild werden immer auf das im link angegebene ziel gesetzt
    history.replaceState(null, null, href);
    $('#page img.page').attr('src', imagePath(page));
    if (/left/i.test(classes)) {
      // linker knopf gedrückt, also -1, aber: rechter knopf nun = linker knopf + 1!
      if (page <= getData('first-page') || page >= getData('last-page')) {
        $('#page a.left').attr('href', '/'+book+'/'+(page));
        $('#page a.right').attr('href', '/'+book+'/'+(page + 1));
      } else {
        $('#page a.left').attr('href', '/'+book+'/'+(page - 1));
        $('#page a.right').attr('href', '/'+book+'/'+(page + 1));
      }
    } else if (/right/i.test(classes)) {
      // rechter knopf gedrückt, also +1, aber: linker knopf nun = rechter knopf - 1!
      if (page <= getData('first-page') || page >= getData('last-page')) {
        $('#page a.left').attr('href', '/'+book+'/'+(page - 1));
        $('#page a.right').attr('href', '/'+book+'/'+(page));
      } else {
        $('#page a.left').attr('href', '/'+book+'/'+(page - 1));
        $('#page a.right').attr('href', '/'+book+'/'+(page + 1));
      }
    }
    e.preventDefault();
  });
}

$(document).keydown(function(e) {
  switch(e.which) {
    case 37: $('a.arrow.left').trigger('click'); break;  // left arrow key
    case 39: $('a.arrow.right').trigger('click'); break; // right arrow key
  }
});

function imagePath(page) {
  return '/assets/books/'+getData('book')+'/page_'+pad(page+(-getData('first-page')))+'.png';
}

function pad(number) {
  var str = ''+number;
  var pad = '0000';
  return (pad.substring(0, pad.length - str.length) + str);
}

function getData(varname) {
  return $('#page').data(varname);
}
