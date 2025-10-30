import jquery from 'jquery';
window.$ = jquery;

import Cookies from 'js-cookie';

import I18n from "vendor/i18n-js/i18n";
import 'translations';

import 'vendor/jquery_mb_extruder/jquery.hoverIntent.min';
import 'vendor/jquery_mb_extruder/jquery.mb.flipText';
import 'vendor/jquery_mb_extruder/mbExtruder';

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

$(document).ajaxStart(function() {
  $('body').css('cursor', 'progress');
}).ajaxStop(function() {
  $('body').css('cursor', 'default');
});

function main() {
  handleSidebar();
  handleSearch();
  handlePageTurns();
  handleSidebarForm();
  handleTermsDialog();
  // handleMouseWheel();
}

/*function handleMouseWheel() {
  $('#page .wrapper img').mousewheel(function(e) {
    switch (e.deltaY) {
      case 1:  $('a.page.left').trigger('click'); break;  // up and back
      case -1: $('a.page.right').trigger('click'); break; // down and forward
    }
    e.preventDefault();
  });
}*/

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
    if (Cookies.get('sidebar_enabled')) {
      Cookies.remove('sidebar_enabled', { path: '/' });
    } else {
      Cookies.set('sidebar_enabled', true, { path: '/', expires: 365 });
    }
  });
  if (Cookies.get('sidebar_enabled')) {
    $('#sidebar').openMbExtruder(true);
  }
}

function handleSearch() {
  $('#search').focus().select();
  $('.navbar-search-form form').submit(function(e) {
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

function updatePageElements(new_book, new_page) {
  var elements = ['cover_page', 'first_page', 'last_page'];
  for (var i = 0; i < elements.length; i++) {
    $('#' + elements[i] + '_link').attr('href', absPath(new_book.slug, new_book[elements[i]]));
  }

  $('#search_book').val(new_book.slug);
  var search = $('#search');
  if (isNumeric(search.val())) {
    search.val(new_page.number);
  }

  $('#sidebar li').each(function() {
    var radio = $(this).find('input:radio');
    if (radio.val() == new_book.slug)
      radio.prop('checked', true);
    $(this).find('input[name=from_book]').val(new_book.slug);
    $(this).find('input[name=from_page]').val(new_page.number);
  });

  for (var key in new_book)
    $('#book').attr('data-' + key.replace('_', '-'), new_book[key]);
  for (var key in new_page)
    $('#page').attr('data-' + key.replace('_', '-'), new_page[key]);

  $('#book a.page.left').attr('href', absPath(new_book.slug, new_page.previous));
  $('#book a.page.left').attr('title', I18n.t('page') + ' ' + new_page.previous);
  $('#book a.page.left').attr('data-target', new_page.previous);
  $('#book a.page.right').attr('href', absPath(new_book.slug, new_page.next));
  $('#book a.page.right').attr('title', I18n.t('page') + ' ' + new_page.next);
  $('#book a.page.right').attr('data-target', new_page.next);
  $('#book img.page').attr('src', absPath('images', new_page.image_file));
  $('#book img.page').attr('title', I18n.t('page') + ' ' + new_page.number);

  history.replaceState(null, null, new_page.path);
  $('title').html(I18n.t('htmltitle', { book: new_book.human_name, page: new_page.number }));
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
