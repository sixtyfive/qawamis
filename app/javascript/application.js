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
  handleArabiziHint();
  handleFlashClosing();
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
      // First-time introduction: slide the book-picker sidebar open
      // automatically so the user can see where it lives. From here on
      // it's their toggle, not the page's.
      $('#sidebar').openMbExtruder();
      // Mirror the cookie that the flap click handler maintains, so the
      // welcome-time opening survives the next full page reload.
      Cookies.set('sidebar_enabled', true, { path: '/', expires: 365 });
      setTimeout(function() { dialog.fadeOut(500); }, 250);
    }
  });
}

function handleArabiziHint() {
  var hint = $('#arabizi_hint');
  if (!Cookies.get('arabizi_hint_dismissed')) {
    hint.show();
  }
  hint.find('.close').on('click', function() {
    Cookies.set('arabizi_hint_dismissed', true, { path: '/', expires: 365 });
    hint.fadeOut(250);
  });
}

function handleExtruder() {
  // https://github.com/pupunzi/jquery.mb.extruder/wiki
  $('#sidebar').buildMbExtruder({
    width: 270,
    position: 'left',
    slideTimer: 150,
    closeOnClick: false,
    // The sidebar should only open/close via its flap. Letting an
    // unrelated click on the page close it is confusing now that the
    // terms dialog uses it as the welcome hand-off.
    closeOnExternalClick: false
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

  // Restore whichever way the sidebar was last left: open or closed.
  // The cookie is written by the flap click above (and by the welcome
  // dialog's auto-open), but the extruder itself starts in a closed
  // state after buildMbExtruder(), so without this every full reload
  // would snap the sidebar shut again.
  if (Cookies.get('sidebar_enabled')) {
    $('#sidebar').openMbExtruder();
  }
}

function handleSearch() {
  var search = $('#search');

  // Flip the search field's dir attribute based on the script of the first
  // non-whitespace character so that Arabic queries ("توح") keep their
  // right-to-left ordering while Arabizi queries ("tw7") render left-to-right.
  // Run on every input event plus once at startup so any server-supplied
  // current_search gets the correct initial direction.
  var rtl_script = /[\u0600-\u06FF\u0590-\u05FF]/; // Arabic, Hebrew
  function updateSearchDir() {
    var first_char = search.val().trim().charAt(0);
    if (!first_char) return;
    search.attr('dir', rtl_script.test(first_char) ? 'rtl' : 'ltr');
  }
  search.on('input', updateSearchDir);
  updateSearchDir();

  search.focus().select();
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

  // Always jump back to the top on actual page changes. Skip only when
  // we're just refreshing sidebar items in place (extruder open, same page).
  if (!update_extruder) {
    window.scrollTo({top: 0, behavior: 'smooth'});
  }

  // Books whose stored root range doesn't cover the current page's root get
  // the lighter "this book has nothing in your current range" styling. This
  // needs to be recomputed on every XHR page change, not only when the
  // sidebar is opened.
  updateSidebarLabels(page.last_root);

  $('#cover_page_link').attr('href', absPath(book.slug, book.cover_page));
  $('#first_page_link').attr('href', absPath(book.slug, book.first_page));
  $('#last_page_link').attr('href', absPath(book.slug, book.last_page));
  $('#last_page_link').text(I18n.t('page')+' '+book.last_page);
  // Highlight the quicknav link that matches the page we're on. The
  // matching server-rendered class is set in _navigation.html.haml via
  // quicknav_link_class; this keeps it in sync after XHR navigation.
  $('#cover_page_link').toggleClass('active', book.cover_page === page.number);
  $('#first_page_link').toggleClass('active', book.first_page === page.number);
  $('#last_page_link').toggleClass('active', book.last_page  === page.number);
  $('#currentroot_range').text(
    page.previous_last_root
      ? I18n.t('currentroot_range', {from: page.previous_last_root, to: page.last_root})
      : I18n.t('currentroot_firstpage', {to: page.last_root})
  );

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
    if ($(this).data('armed') === true) {
      $(this).removeData('armed');
      $(this).removeClass('pending');
    }
    // Keep each book's destination in sync with the current root after
    // searches and page turns as well as when refreshing the open sidebar.
    updateSidebarItems(page, label, book_input, page_input);
  });
}

function updateSidebarLabels(current_root) {
  // Marks each sidebar book as `same_root` (its range covers the current
  // root) or `cover_page` (it would only show the book's first page for
  // the current root). Cheap, runs on every page change without AJAX.
  if (!current_root) return;
  $('#sidebar li').each(function() {
    var $li = $(this);
    var first_root = $li.data('bookFirstRoot');
    var last_root  = $li.data('bookLastRoot');
    var label = $li.find('label').first();
    if (!first_root || !last_root) {
      label.removeClass('same_root').addClass('cover_page');
      return;
    }
    var in_range = current_root >= first_root && current_root <= last_root;
    // Open-ended last page: even when current_root is past last_root
    // alphabetically, the book's last page could still hold it if the
    // 2-character prefixes agree (e.g. hw3_en ends at "يونو" while
    // viewing hw5_de page 1452 last_root "يونيو"). Mirrors
    // Book#could_contain? on the server so this label colour never
    // disagrees with the navigation warning.
    var same_prefix = current_root.length >= 2 &&
                      last_root.length >= 2 &&
                      current_root.substring(0, 2) === last_root.substring(0, 2);
    if (in_range || same_prefix) {
      label.removeClass('cover_page').addClass('same_root');
    } else {
      label.removeClass('same_root').addClass('cover_page');
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

  // The cover / first / last links in the top navigation also jump between
  // pages. Route them through the same XHR path as the left/right arrows so
  // the sidebar isn't rebuilt by a full reload — tapping these should feel
  // identical to a page turn.
  $('#cover_page_link, #first_page_link, #last_page_link').click(function(e) {
    $.ajax({
      url: $(this).attr('href'),
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
    const $li = $(this);
    // Two-click confirmation: when the previously displayed root isn't
    // available in the chosen book the server returns a warning the first
    // time. Mark the <li> as armed so a second click on the same book
    // opens its first page.
    const armed = $li.data('armed') === true;
    const book = $li.find('input[type=radio]').val();
    const page = armed ? 1 : $li.find('input[type=hidden]').val();
    let data = $li.serialize();
    if (armed) {
      data += (data ? '&' : '') + 'force=1';
    }
    $.ajax({
      url: absPath(book, page),
      type: 'GET',
      dataType: 'json',
      data: data,
      success: function(results) {
        $('main .alert').remove();
        if (results.flash) {
          showAlert(results.flash[0], results.flash[1]);
          // Bring the just-shown flash alert into view — otherwise a user
          // scrolled partway down their current page won't see it.
          window.scrollTo({top: 0, behavior: 'smooth'});
        }
        if (results.root_warning) {
          // The server kept us on the previous book/page; just arm this
          // <li> for a second click and don't touch the page elements.
          $li.data('armed', true);
          $li.addClass('pending');
        } else {
          if (results.book && results.page) {
            updatePageElements(results.book, results.page);
          }
          $li.removeData('armed');
          $li.removeClass('pending');
        }
      }
    });
    e.preventDefault();
  });
}

function handleFlashClosing() {
  $('main').on('click', '.alert .close', function() {
    $(this).parent().fadeOut(250, function() {
      $(this).remove();
    });
  });
}
