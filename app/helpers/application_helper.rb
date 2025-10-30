module ApplicationHelper
  def current_search
    last_search
  end

  def last_search
    JSON.parse(cookies[:search_history]).last unless cookies[:search_history].blank?
  end

  def page_with_root(book, root)
    if page = book.pages.find_by_root(root)
      page.number
    else
      flash[:notice] = t(:nosuchentry_in_selectedbook)
      1
    end
  end
end
