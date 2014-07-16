class PagesController < ApplicationController
  before_action :set_books, :init_session

  # GET /book.name/page.number
  def show
    @page = @book.pages.find_by_number(params[:page])
    respond_to do |format|
      format.html do
        if @page
          cookies[:page] = {value: params[:page], expires: 1.year.from_now}
        else
          if cookies[:page]
            redirect_to @book.pages.find_by_number(cookies[:page])
          else
            @page = @book.pages.first_numbered
          end
        end
      end
      format.json do
        render json: {book: @page.book.serialize, page: @page.serialize} if @page
      end
    end
  end

  def find
    # POST /books
    if params[:from_book] && params[:from_page] && @from_book = params[:from_book].split('_')
      if @from_book = Book.find_by(name: @from_book[0], language: @from_book[1])
        from_book_page = @from_book.pages.find_by_number(params[:from_page])
        @search = from_book_page.last_root
      end
    else
      # GET /search_string
      # POST /pages
      @search = params[:search]
    end
    logger.debug "*** find: trying to look up root in currently displayed book."
    if @search
      if @search.number?
        @page = @book.pages.find_by_number(@search)
      else
        unless @page = @book.pages.find_by_root(@search)
          # No search results in current book.
          if @from_book && @book = params[:book].split('_')
            # Book was explicitly requested, so show its first page instead.
            @book = Book.find_by(name: @book[0], language: @book[1])
            @page = @book.first_page
            flash[:notice] = t(:nosuchentry_in_selectedbook)
          else
            # No explicit book was requested, so try to find search in another.
            logger.debug "*** find: trying to look up root in all available books."
            if @page = Page.find_by_root(@search)
              flash[:notice] = t(:nosearchresults_in_selectedbook, book: t("books.#{@page.book.full_name}"))
            end
          end
        end
      end
      flash[:warn] = t(:nosearchresults) unless @page
    else
      if @from_book && @book = params[:book].split('_')
        # Book was explicitly requested, but no entry to be displayed was given.
        # Most likely, a page <0 was displayed.
        @book = Book.find_by(name: @book[0], language: @book[1])
        @page = @book.pages.find_by_number(params[:from_page]) || @book.pages.first
      end
    end
    update_search_history
    respond_to do |format|
      format.html do
        @page ||= (cookies[:page] ? @book.pages.find_by_number(cookies[:page]) : @book.pages.first_numbered)
        redirect_to @page
      end
      format.json do
        flash.discard
        render json: {
          book: @page.book.serialize, 
          page: @page.serialize, 
          flash: flash.first, 
          search_history: @search_history.reverse
        }
      end
    end
  end

  private

  def set_books
    if params[:book] && book = params[:book].split('_')
      # Params present, format correct.
      if @book = Book.find_by(name: book[0], language: book[1])
        cookies[:book] = {value: params[:book], expires: 1.year.from_now}
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
        @book = Book.find_by(name: book[0], language: book[1])
      end
      # No preference present, falling back to default.
      @book ||= Book.default
    end
    # For the sidebar.
    @books = Book.all
  end
  
  def page_url(page)
    page.path + (@search ? "?search=#{@search}" : '')
  end
  
  def book_url(book)
    book.first_page.path
  end
    
  def update_search_history
    if params[:books].nil?
      _cookies = @search_history
      _cookies.shift if (_cookies.length > 25)
      unless params[:search].blank? || @search_history.last == params[:search]
        _cookies << params[:search] 
      end
      _cookies = _cookies.reverse.uniq.reverse
      cookies[:search_history] = {value: JSON.generate(_cookies), expires: 1.year.from_now}
    end
  end

  def init_session
    if cookies[:search_history].blank?
      @search_history = []
    else
      @search_history = JSON.parse(cookies[:search_history])
    end
  end
end
