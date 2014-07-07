$(document).ready(function() {
  handlePageChanges();
});

function handlePageChanges() {
  var href, book, page, classes;
  $('#book a.page').click(function(e) {
    href = $(this).attr('href');
    book = href.split('/')[1];
    page = parseInt(href.split('/')[2]);
    classes = $(this).attr('class');
    /* location und bild werden immer auf das im link angegebene ziel gesetzt */
    history.pushState(null, null, page);
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
