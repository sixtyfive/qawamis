class PagesController < ApplicationController
  before_action :set_books, :init_session

  # GET /book.name/page.number
  def show
    if params[:page]
      @page = @book.pages.find_by_number(params[:page])
    else
      @page = @book.pages.first_numbered
    end
  end

  # GET /search_string
  # POST /pages
  def find
    @search = params[:search]
    begin
      @page = Page.find_by_root(@search)
      _cookies = @search_history
      _cookies.shift if (_cookies.length > 50)
      _cookies << @search if @page
      _cookies.uniq!
      cookies[:search_history] = JSON.generate(_cookies)
    rescue
      flash.now[:alert] = 'Keine Suchergebnisse. Versuchen Sie die Eingabe einer Wurzel anstatt eines Wortes.'
    end
    respond_to do |format|
      format.html { @page ||= @book.pages.first_numbered; render :show }
      format.json { render json: {page: @page, search_history: @search_history.reverse} }
    end
  end

  private
    
  def set_books
    @books = Book.all
    if params[:book] 
      book, language = params[:book].split('_')
      @book = Book.find_by(name: book, language: language)
    else
      @book = Book.first
    end
  end

  def init_session
    if cookies[:search_history].nil?
      @search_history = []
    else
      @search_history = JSON.parse(cookies[:search_history])
    end
  end
end
