$(document).ready(main);           // fresh page loads
$(document).on('page:load', main); // cached page loads and turbolinks

$(document).keydown(function(e) {
  switch(e.which) {
    /* javascript-version
    case 37: $('a.page.left').trigger('click'); break;  // left arrow key
    case 39: $('a.page.right').trigger('click'); break; // right arrow key*/
    // static version
    case 37: location.href = $('a.page.left').attr('href'); break;
    case 39: location.href = $('a.page.right').attr('href'); break;
  }
});

function main() {
  /* disabled for now. first the static version has to function properly.
  handlePageChanges();
  handleSearchRequests();*/
  handleSidebar();
}

function handleSidebar() {
  $('#sidebar').buildMbExtruder({
    width: 270,
    position: 'left',
    slideTimer: 150,
    closeOnClick: false,
    closeOnExternalClick: false
  });
  // needs to be done separately!
  $('.flap').click(function() {
    if ($.cookie('sidebar_enabled')) {
      $.removeCookie('sidebar_enabled');
    } else {
      $.cookie('sidebar_enabled', true);
    }
  }); if ($.cookie('sidebar_enabled')) {
    $('#sidebar').openMbExtruder(true);
  }
  $('input[type=radio]').click(function() {
    $(this).closest('form').submit();
  });
}

function handleBookSwitch() {
}

function handleSearchRequests() {
  $('form').submit(function(e) {
    $.ajax({
      url: '/pages',
      type: 'POST',
      dataType: 'json',
      data: $(this).serialize(),
      success: function(results) {
        if (results['flash']) {
          showAlert(results['flash'][0], results['flash'][1]);
        }; if (results['page']) {
          displayResults(results['page']);
          updatePreviousSearches(results['search_history']);
        }
      }
    })
    e.preventDefault();
  });
}

function showAlert(severity, message) {
  $('main .alert').remove();
  var danger_or_success = 'danger';
  if (severity == 'notice') 
    danger_or_success = 'success';
  $('main').prepend("\
    <div class='alert alert-"+danger_or_success+"'>\
      <button aria-hidden='true' class='close' data-dismiss='alert' type='button'>&times;</button>\
      <div id='flash_"+severity+"'>"+message+"</div>\
    </div>\
  ");
}

function displayResults(page_object) {
  var book, page, prev_page, next_page, title;
  book = getData('book');
  page = page_object['number'];
  history.replaceState(null, null, '/'+book+'/'+page);
  $('div.alert.alert-danger').remove();
  // image
  title = getData('page')+' '+page;
  $('#page img.page').attr('src', imagePath(page));
  $('#page img.page').attr('title', title);
  // arrow left
  if (page == getData('first-page')) {
    prev_page = page;
  } else {
    prev_page = page-1;
  }
  title = getData('page')+' '+prev_page;
  $('#page a.left').attr('href', '/'+book+'/'+prev_page);
  $('#page a.left').attr('title', title);
  // arrow right
  if (page == getData('last-page')) {
    next_page = page;
  } else {
    next_page = page+1;
  }
  var next_page = page+1;
  title = getData('page')+' '+next_page;
  $('#page a.right').attr('href', '/'+book+'/'+next_page);
  $('#page a.right').attr('title', title);
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
  var href, book, page, classes, title;
  $('#page a.page').click(function(e) {
    href = $(this).attr('href');
    book = getData('book');
    page = parseInt(href.split('/')[2]);
    classes = $(this).attr('class');
    // location und bild werden immer auf das im link angegebene ziel gesetzt
    history.replaceState(null, null, href);
    title = getData('page')+' '+page;
    $('#page img.page').attr('src', imagePath(page));
    $('#page img.page').attr('title', title);
    title = getData('page')+' ';
    if (/left/i.test(classes)) {
      // linker knopf gedrückt, also -1, aber: rechter knopf nun = linker knopf + 1!
      if (page <= getData('first-page') || page >= getData('last-page')) {
        $('#page a.left').attr('href', '/'+book+'/'+page);
        $('#page a.left').attr('title', title+page);
      } else {
        $('#page a.left').attr('href', '/'+book+'/'+(page-1));
        $('#page a.left').attr('title', title+(page-1));
      }
      $('#page a.right').attr('href', '/'+book+'/'+(page+1));
      $('#page a.right').attr('title', title+(page+1));
    } else if (/right/i.test(classes)) {
      // rechter knopf gedrückt, also +1, aber: linker knopf nun = rechter knopf - 1!
      if (page <= getData('first-page') || page >= getData('last-page')) {
        $('#page a.right').attr('href', '/'+book+'/'+page);
        $('#page a.right').attr('title', title+page);
      } else {
        $('#page a.right').attr('href', '/'+book+'/'+(page+1));
        $('#page a.right').attr('title', title+(page+1));
      }
      $('#page a.left').attr('href', '/'+book+'/'+(page-1));
      $('#page a.left').attr('title', title+(page-1));
    }
    e.preventDefault();
  });
}

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
