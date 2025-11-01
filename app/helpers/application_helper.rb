module ApplicationHelper
  def current_search
    last_search
  end

  def last_search
    JSON.parse(cookies[:search_history]).last unless cookies[:search_history].blank?
  end

  def most_equivalent_page(book, page)
    page ? page.number : book.pages.first_numbered.number
  end

  def label_tag_class(current_book_page, page)
    (page && (current_book_page.number != 1 && page.number == 1)) ? 'cover_page' : 'same_root'
  end
end
