$(document).ready(main); /* fresh page loads */
$(document).on('page:load', main); /* cached page loads and turbolinks */

function main() {
  replaceSearchURL();
  handlePageChanges();
  handleSearchRequests();
}

function replaceSearchURL() {
  history.replaceState(null, null, '/'+getBookName()+'/'+getPageNumber())
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
          updatePreviousSearches(results['previous_searches']);
        }
      }
    })
    e.preventDefault();
  });
}

function showNoResultsAlert() {
  $('main').prepend("\
    <div class='alert alert-danger'>\
      <button aria-hidden='true' class='close' data-dismiss='alert' type='button'>&times;</button>\
      <div id='flash_alert'>Keine Suchergebnisse. Versuchen Sie die Eingabe einer Wurzel anstelle eines Wortes.</div>\
    </div>\
  ");
}

function displayResults(page_object) {
  var book = page_object['book'];
  var page = page_object['id'];
  history.replaceState(null, null, '/'+getBookName()+'/'+page);
  $('#book img.page').attr('src', getImagePath(page+getFirstNumberedPage()-1));
  $('#book a.left').attr('href', '/'+book+'/'+(page-1));
  $('#book a.right').attr('href', '/'+book+'/'+(page+1));
  $('div.alert.alert-danger').remove();
}

function updatePreviousSearches(previous_searches) {
  var html = '';
  for (var i in previous_searches) {
    word = previous_searches[i];
    html += "<a class='navbar-brand' href='/"+word+"'>"+word+"</a>";
  }
  $('#previous_searches').html(html);
}

function handlePageChanges() {
  var href, book, page, classes;
  $('#book a.page').click(function(e) {
    href = $(this).attr('href');
    book = getBookName();
    page = parseInt(href.split('/')[2]);
    classes = $(this).attr('class');
    /* location und bild werden immer auf das im link angegebene ziel gesetzt */
    history.replaceState(null, null, href);
    $('#book img.page').attr('src', getImagePath(page+getFirstNumberedPage()-1));
    if (/left/i.test(classes)) {
      /* linker knopf gedrückt, also -1, aber: rechter knopf nun = linker knopf + 1! */
      if (page <= 1-getFirstNumberedPage() || page >= getNumberOfPages()-getFirstNumberedPage()) {
        $('#book a.left').attr('href', '/'+book+'/'+(page));
        $('#book a.right').attr('href', '/'+book+'/'+(page + 1));
      } else {
        $('#book a.left').attr('href', '/'+book+'/'+(page - 1));
        $('#book a.right').attr('href', '/'+book+'/'+(page + 1));
      }
    } else if (/right/i.test(classes)) {
      /* rechter knopf gedrückt, also +1, aber: linker knopf nun = rechter knopf - 1! */
      if (page <= 1-getFirstNumberedPage() || page >= getNumberOfPages()-getFirstNumberedPage()) {
        $('#book a.left').attr('href', '/'+book+'/'+(page - 1));
        $('#book a.right').attr('href', '/'+book+'/'+(page));
      } else {
        $('#book a.left').attr('href', '/'+book+'/'+(page - 1));
        $('#book a.right').attr('href', '/'+book+'/'+(page + 1));
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

function getBookName() {
  return $('#book').data('name');
}

function getPageNumber() {
  return $('#book').data('page-number');
}

function getFirstNumberedPage() {
  return parseInt($('#book').data('first-numbered-page'));
}

function getNumberOfPages() {
  return parseInt($('#book').data('number-of-pages'));
}

function getImagePath(page) {
  return '/assets/books/'+$('#book').data('id')+'/page_'+pad(page, 4)+'.png';
}

function pad(str, max) {
  str = str.toString();
  return str.length < max ? pad('0' + str, max) : str;
}
