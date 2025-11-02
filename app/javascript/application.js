import jquery from 'jquery';
window.$ = jquery;

import Cookies from 'js-cookie';

// an unknown version from sometime in 2014
// there's something newer (2.6.0) available via yarn,
// but no point in trying to make it work since this sort
// of thing is so much simpler nowadays; better get rid of
// entirely...
import 'vendor/jquery_mb_extruder/jquery.hoverIntent.min';
import 'vendor/jquery_mb_extruder/jquery.mb.flipText';
import 'vendor/jquery_mb_extruder/mbExtruder';

// very hackish, might need to revisit once importmap-rails stabilizes
// and/or i18n-js either adapts to it or goes extinct. apparently, the
// more modern way would be to feed translated strings in via hotwire
import translations from 'translations';
I18n = new I18n.I18n(translations);
I18n.defaultLocale = 'en';
I18n.locale = document.documentElement.lang;
I18n.enableFallback = true;

$(document).ready(main); 
$(document).on('page:load', main); // cached page loads and turbolinks

$(document).keydown(function(e) {
  switch (e.which) {
    // paging
    case 37: $('a.page.left').trigger('click'); break; // left arrow
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

$(document).ajaxStart(function() {
  $('body').css('cursor', 'progress');
}).ajaxStop(function() {
  $('body').css('cursor', 'default');
});

function main() {
  handleExtruder();
  handleSearch();
  handlePageTurns();
  handleSidebarForm();
  handleTermsDialog();
  // handleMouseWheel(); // FIXME: why did I disable this?
}

function handleMouseWheel() {
  $('#page .wrapper img').on("mousewheel", function(e) {
    switch (e.deltaY) {
      case 1:  $('a.page.left').trigger('click'); break;  // up and back
      case -1: $('a.page.right').trigger('click'); break; // down and forward
    }
    e.preventDefault();
  });
}

function handleTermsDialog() {
  var dialog = $('#terms_dialog');
  if (!Cookies.get('terms_agreed')) {
    dialog.show();
  }
  var checkbox = $('#terms_dialog input');
  checkbox.change(function() {
    if (checkbox.is(':checked')) {
      Cookies.set('terms_agreed', true, { path: '/', expires: 365 });
      setTimeout(function() { dialog.fadeOut(500); }, 250);
    }
  });
}

function handleExtruder() {
  // https://github.com/pupunzi/jquery.mb.extruder/wiki
  $('#sidebar').buildMbExtruder({
    width: 270,
    position: 'left',
    slideTimer: 150,
    closeOnClick: false,
    closeOnExternalClick: true
  });

  // this needs to be done separately and not
  // via the buildMbExtruder() callback options
  // above
  $('.flap').on("click", function() {
    if (Cookies.get('sidebar_enabled')) {
      // it's closed and opening
      updatePageElements();
      Cookies.remove('sidebar_enabled', {path: '/'});
    } else {
      // it's open and closing
      Cookies.set('sidebar_enabled', true, {path: '/', expires: 365});
    }
  });
}

function handleSearch() {
  $('#search').focus().select();
  $('#search_form form').submit(function(e) {
    $.ajax({
      url: '/search',
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
    <div class='alert alert-" + danger_or_success + "'>\
      <button aria-hidden='true' class='close' data-dismiss='alert' type='button'>&times;</button>\
      <div id='flash_" + severity + "'>" + message + "</div>\
    </div>\
  ");
}

function getDataFromDiv(selector) {
  const data = {};
  $(selector).each(function() {
    $.each(this.attributes, function(_, attr) {
      if (attr.name.startsWith('data-')) {
        const key = attr.name
          .replace(/^data-/, '')
          .replace(/-/g, '_');
        data[key] = attr.value;
      }
    });
  });
  return data;
}

function updatePageElements(book = null, page = null) {
  var update_extruder = false;
  if (!book && !page) update_extruder = true;

  if (!book) book = getDataFromDiv('main #book');
  if (!page) page = getDataFromDiv('main #book #page');

  $('#cover_page_link').attr('href', absPath(book.slug, book.cover_page));
  $('#first_page_link').attr('href', absPath(book.slug, book.first_page));
  $('#last_page_link').attr('href', absPath(book.slug, book.last_page));
  $('#last_page_link').text(I18n.t('page')+' '+book.last_page);

  $('#search_book').val(book.slug);
  var search = $('#search');
  if (isNumeric(search.val())) {
    search.val(page.number);
  }

  for (var key in book)
    $('body main #book').attr('data-' + key.replace('_', '-'), book[key]);
  for (var key in page)
    $('body main #book #page').attr('data-' + key.replace('_', '-'), page[key]);

  $('#book a.page.left').attr('href', absPath(book.slug, page.previous));
  $('#book a.page.left').attr('title', I18n.t('page') + ' ' + page.previous);
  $('#book a.page.left').attr('data-target', page.previous);
  $('#book a.page.right').attr('href', absPath(book.slug, page.next));
  $('#book a.page.right').attr('title', I18n.t('page') + ' ' + page.next);
  $('#book a.page.right').attr('data-target', page.next);
  $('#book img.page').attr('src', absPath('images', page.image_file));
  $('#book img.page').attr('title', I18n.t('page') + ' ' + page.number);

  history.replaceState(null, null, page.path);
  $('title').html(I18n.t('htmltitle', {book: book.human_name, page: page.number}));
  
  $('#sidebar li').each(function() {
    var book_input = $(this).find('input[name=book_slug]');
    var page_input = $(this).find('input[type=hidden]');
    var label = $(this).find('label');
    if (book_input.val() == book.slug) {
      book_input.prop('checked', true);
    }
    if (update_extruder) {
      // this is expensive, so only done with the extuder open
      updateSidebarItems(page, label, book_input, page_input);
    }
  });
}

function updateSidebarItems(current_page, label, book_input, page_input) {
  console.log([book_input.val(), page_input.val()]);
  $.ajax({
    url: '/search',
    type: 'POST',
    dataType: 'json',
    data: {
      authenticity_token: $('#search_form form input[name=authenticity_token]').val(),
      book_slug: book_input.val(),
      query: current_page.last_root
    },
    success: function(results) {
      var new_page_number = results.page.number;
      page_input.val(new_page_number);
      if (current_page.number != 1 && new_page_number == 1) {
        label.removeClass('same_root').addClass('cover_page');
      } else {
        label.removeClass('cover_page').addClass('same_root');
      }
    }
  });
}

function absPath() {
  var path = '/';
  for (var i = 0; i < arguments.length; i++) {
    path += arguments[i] + '/';
  }
  return path.slice(0, -1);
}

function isNumeric(_var) {
  return !isNaN(_var) && _var != '';
}

function updateSearchHistory(search_history) {
  var html = '';
  for (var i in search_history) {
    var word = search_history[i];
    html += "<a class='navbar-brand' href='/" + word + "'>" + word + "</a>";
  }
  $('#search_history').html(html);
}

function handlePageTurns() {
  $('#sidebar').closeMbExtruder(true);
  $('#book a.page').click(function(e) {
    $.ajax({
      url: absPath($('#book').attr('data-slug'), $(this).attr('data-target')),
      type: 'GET',
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

function handleSidebarForm() {
  $('#sidebar form li').click(function(e) {
    const book = $(this).find('input[type=radio]').val();
    const page = $(this).find('input[type=hidden]').val();
    $.ajax({
      url: absPath(book, page),
      type: 'GET',
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
