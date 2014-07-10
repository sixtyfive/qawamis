class PagesController < ApplicationController
  before_action :set_books, :init_session

  # GET /book.name/page.number
  def show
    if params[:page] && @page = @book.pages.find_by_number(params[:page])
      cookies[:page] = params[:page]
    else
      if cookies[:page]
        redirect_to @book.pages.find_by_number(cookies[:page])
      else
        @page = @book.pages.first_numbered
      end
    end
  end

  def find
    # POST /books
    if params[:from_book] && params[:from_page] && @from_book = params[:from_book].split('_')
      if @from_book = Book.find_by(name: @from_book[0], language: @from_book[1])
        from_book_page = @from_book.pages.find_by_number(params[:from_page])
        @search = from_book_page.last_root || ''
      end
    else
      # GET /search_string
      # POST /pages
      @search = params[:search]
    end
    logger.warn "*** find: trying to look up root in currently displayed book."
    unless @page = @book.pages.find_by_root(@search)
      # No search results in current book.
      if @from_book && @book = params[:book].split('_')
        # Book was explicitly requested, so show its first page instead.
        @page = Book.find_by(name: @book[0], language: @book[1]).first_page
        flash[:notice] = t(:nosuchentry_in_selectedbook)
      else
        # No explicit book was requested, so try to find search in another.
        logger.warn "*** find: trying to look up root in all available books."
        if @page = Page.find_by_root(@search)
          flash[:notice] = t(:nosearchresults_in_selectedbook, book: t("books.#{@page.book.full_name}"))
        end
      end
    end
    if @page
      maintain_search_history
    else
      flash[:warn] = t(:nosearchresults)
    end
    respond_to do |format|
      format.html do
        @page ||= (cookies[:page] ? @book.pages.find_by_number(cookies[:page]) : @book.pages.first_numbered)
        redirect_to @page
      end
      format.json do
        render json: {page: @page, flash: flash.first, search_history: @search_history.reverse}
      end
    end
  end

  private

  def maintain_search_history
    _cookies = @search_history
    _cookies.shift if (_cookies.length > 50)
    _cookies << @search
    _cookies.uniq!
    cookies[:search_history] = JSON.generate(_cookies)
  end

  def set_books
    if params[:book] && book = params[:book].split('_')
      # Params present, format correct.
      if @book = Book.find_by(name: book[0], language: book[1])
        cookies[:book] = params[:book]
      else
        # Got bogus info!
        if cookies[:book] && book = cookies[:book].split('_')
          unless @book = Book.find_by(name: book[0], language: book[1])
            # No preference present, falling back to default.
            @book = Book.default
          end
        else
          # No preference present, falling back to default.
          @book = Book.default
        end
        flash[:warn] = t(:nosuchbook, book: t("books.#{@book.full_name}"))
        redirect_to(@book)
      end
    else
      if cookies[:book] && book = cookies[:book].split('_')
        # Cookies present, format correct.
        unless @book = Book.find_by(name: book[0], language: book[1])
          # No preference present, falling back to default.
          @book = Book.default
        end
      end
    end
    # For the sidebar.
    @books = Book.all
  end
  
  def page_url(page)
    page.path
  end
  
  def book_url(book)
    book.first_page.path
  end

  def init_session
    if cookies[:search_history].nil?
      @search_history = []
    else
      @search_history = JSON.parse(cookies[:search_history])
    end
  end
end
