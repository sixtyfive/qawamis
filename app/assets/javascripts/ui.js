$(document).ready(main);           // fresh page loads
$(document).on('page:load', main); // cached page loads and turbolinks

$(document).keydown(function(e) {
  switch (e.which) {
    // paging
    case 37: $('a.page.left').trigger('click'); break;  // left arrow
    case 39: $('a.page.right').trigger('click'); break; // right arrow
    // make sure any other key press is used for search.
    default: if (!$('#search').is(':focus')) $('#search').focus().select(); 
  }
  switch (e.which) {
    // arrow keys should be reserved for page scrolling
    // and browsing, search field navigation is disabled.
    case 37: // left arrow
    case 38: // up arrow
    case 39: // right arrow
    case 40: // down arrow
    $('#book').focus();
    break;
  }
});

function main() {
  handleSidebar();
  handleSearch();
  handlePageTurns();
  handleTermsDialog();
  handleMouseWheel();
}

function handleMouseWheel() {
  $('#page .wrapper img').mousewheel(function(e) {
    switch (e.deltaY) {
      case 1:  $('a.page.left').trigger('click'); break;  // up and back
      case -1: $('a.page.right').trigger('click'); break; // down and forward
    }
    e.preventDefault();
  });
}

function handleTermsDialog() {
  var dialog = $('#terms_dialog');
  if (!$.cookie('terms_agreed')) {
    dialog.show();
  }
  var checkbox = $('#terms_dialog input');
  checkbox.change(function() {
    if (checkbox.is(':checked')) {
      $.cookie('terms_agreed', true, {path: '/'});
      setTimeout(function() {dialog.fadeOut(500)}, 250);
    }
  });
}

function handleSidebar() {
  $('#sidebar').buildMbExtruder({
    width: 270,
    position: 'left',
    slideTimer: 150,
    closeOnClick: false,
    closeOnExternalClick: false
  });
  // needs to be done separately and not through
  // the buildMbExtruder() callback options.
  $('.flap').click(function() {
    if ($.cookie('sidebar_enabled')) {
      $.removeCookie('sidebar_enabled', {path: '/'});
    } else {
      $.cookie('sidebar_enabled', true, {path: '/'});
    }
  }); if ($.cookie('sidebar_enabled')) {
    $('#sidebar').openMbExtruder(true);
  }
  $('input[type=radio]').click(function() {
    $(this).closest('form').submit();
  });
}

function handleSearch() {
  $('#search').focus().select();
  $('.navbar-search-form form').submit(function(e) {
    $.ajax({
      url: '/pages',
      type: 'POST',
      dataType: 'json',
      data: $(this).serialize(),
      success: function(results) {
        $('main .alert').remove();
        if (results.flash)
          showAlert(results.flash[0], results.flash[1]);
        if (results.book && results.page) {
          updatePageElements(results.book, results.page);
          updateSearchHistory(results.search_history);
        }
      }
    });
    e.preventDefault();
  });
}

function showAlert(severity, message) {
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

function updatePageElements(new_book, new_page) {
  // new_book: id, name, language, first_numbered_page, cover_page,
  //           first_page, last_page, full_name, human_name
  // new_page: id, number, last_root, book_id, image_file, path,
  //           previous, next
  //
  // #quicknav:
  // - #cover_page_link (href = new page)
  // - #first_page_link (href = new page)
  // - #last_page_link (href = new page)
  elements = ['cover_page', 'first_page', 'last_page'];
  for (var i=0; i<elements.length; i++) {
    $('#'+elements[i]+'_link').attr('href', absPath(new_book.full_name, new_book[elements[i]]));
  }
  // .navbar-search-form:
  // - #search_book (value = new book)
  // - #search (value = new page if it was numeric before)
  // (search history is being taken care of separately)
  $('#search_book').val(new_book.full_name);
  search = $('#search');
  if (isNumeric(search.val())) {
    search.val(new_page.number);
  }
  // #sidebar:
  // - li (each one!)
  //   - input:radio (check if value = new book)
  //   - input[name=from_book] (value = new book)
  //   - input[name=from_page] (value = new page)
  $('#sidebar li').each(function() {
    radio = $(this).find('input:radio');
    if (radio.val() == new_book.full_name) 
      radio.prop('checked', true);
    $(this).find('input[name=from_book]').val(new_book.full_name);
    $(this).find('input[name=from_page]').val(new_page.number);
  });
  // #book[data-...] and
  // - #page[data-...]:
  //   - a.page.left (href = new page's previous_page, title = new page's previous_page, data-target = new page's previous_page)
  //   - a.page.right (href  = new page's next_page, title = new page's next_page, data-target = next page's next_page)
  //   - img.page (src = new page's image_path, title = new page)
  for (var key in new_book)
    $('#book').attr('data-'+key.replace('_', '-'), new_book[key]);
  for (var key in new_page)
    $('#page').attr('data-'+key.replace('_', '-'), new_page[key]);
  $('#book a.page.left').attr('href', absPath(new_book.full_name, new_page.previous));
  $('#book a.page.left').attr('title', I18n.t('page')+' '+new_page.previous);
  $('#book a.page.left').attr('data-target', new_page.previous);
  $('#book a.page.right').attr('href', absPath(new_book.full_name, new_page.next));
  $('#book a.page.right').attr('title', I18n.t('page')+' '+new_page.next);
  $('#book a.page.right').attr('data-target', new_page.next);
  $('#book img.page').attr('src', absPath('assets', new_page.image_file))
  $('#book img.page').attr('title', I18n.t('page')+' '+new_page.number)
  // Last but not least, the URL
  // entry bar and the page title:
  history.replaceState(null, null, new_page.path)
  $('title').html(I18n.t('htmltitle', {book: new_book.human_name, page: new_page.number}));
}

function absPath() {
  var path = '/';
  for (var i=0; i<arguments.length; i++) {
    path += arguments[i]+'/';
  }
  return path.slice(0, -1);
}

function isNumeric(_var) {
  return !isNaN(_var) && _var != '';
}

function updateSearchHistory(search_history) {
  var html = '';
  for (var i in search_history) {
    word = search_history[i];
    html += "<a class='navbar-brand' href='/"+word+"'>"+word+"</a>";
  }
  $('#search_history').html(html);
}

function handlePageTurns() {
  $('#book a.page').click(function(e) {
    $.ajax({
      url: absPath($('#book').attr('data-full-name'), $(this).attr('data-target')),
      type: 'POST',
      dataType: 'json',
      data: $(this).serialize(),
      success: function(results) {
        $('main .alert').remove();
        updatePageElements(results.book, results.page);
      }
    });
    e.preventDefault();
  });
}
