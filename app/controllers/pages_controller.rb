class PagesController < ApplicationController
  before_action :init_cookies, :set_books
  before_action :set_book, except: [:index]

  def index
    redirect_to("/#{Book.default.name}_#{Book.default.language}/1")
  end

  # GET /book.name/page.number
  # POST /book.name/page.number
  def show
    if @page = Page.find_by(book: @book, number: params[:page])
      cookies[:book_slug] = {value: @book.slug, expires: 1.year.from_now}
      cookies[:page] = {value: @page.number, expires: 1.year.from_now}
    end
    respond_to do |format|
      format.html do
        @page ||= @book.pages.first_numbered
      end
      format.json do
        render(json: {book: @page.book.serialize, page: @page.serialize}) if @page
      end
    end
  end

=begin
  FIXME: add these in somewhere again
  - flash[:notice] = t(:nosuchentry_in_selectedbook)
  - logger.debug "*** find: trying to look up root in all available books."
  - flash[:notice] = t(:nosearchresults_in_selectedbook, book: t("books.#{@page.book.slug}"))
  - flash[:warn] = t(:nosearchresults) unless @page
=end
  def find
    @query = params[:query]
    @page = @book.pages.find_by_number(@query) if @query.number?
    @page ||= @book.pages.find_by_root(@query)
    respond_to do |format|
      format.html do
        redirect_to(@page.path)
      end
      format.json do
        flash.discard
        render json: {
          book: @page.book.serialize, 
          page: @page.serialize, 
          flash: flash.first, 
          search_history: @search_history
        }
      end
    end
    update_search_history
  end

  private

  # for the sidebar
  def set_books
    @books = Book.all
  end

  def set_book
    @book = if params[:book_slug]
      book, language = params[:book_slug].split('_')
      Book.find_by(name: book, language: language)
    elsif cookies[:book_slug]
      book, language = cookies[:book_slug].split('_')
      Book.find_by(name: book, language: language)
    else
      Book.default
    end
  end
  
  def update_search_history
    array = @search_history
    query = params[:query]
    array << query if !query.blank? && array.last != query
    cookies[:search_history] = {value: JSON.generate(array.uniq.last(25)), expires: 1.year.from_now}
  end

  def init_cookies
    string = cookies[:search_history]
    string = [].to_s if string.blank?
    @search_history = JSON.parse(string)
  end
end
