class PagesController < ApplicationController
  before_action :init_cookies, :set_books
  before_action :set_book, except: [:index]

  # GET /
  def index
    redirect_to("/#{Book.default.name}_#{Book.default.language}/1")
  end

  # GET /:book_slug/:page
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

  # GET /:query
  # POST /search
  def find
    @query = params[:query]
    @page = if @query.number?
      @book.pages.find_by_number(@query)
    else
      update_search_history
      @book.pages.find_by_root(@query)
    end
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
          search_history: @search_history.reverse
        }
      end
    end
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
    end
    @book ||= Book.default
  end
  
  def update_search_history
    array = @search_history
    query = params[:query]
    array << query
    @search_history = array.reject(&:blank?).uniq.last(25)
    cookies[:search_history] = {value: JSON.generate(@search_history), expires: 1.year.from_now}
  end

  def init_cookies
    string = cookies[:search_history]
    string = [].to_s if string.blank?
    @search_history = JSON.parse(string)
  end
end
