class PagesController < ApplicationController
  before_action :set_book, :init_session

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
    # Deal with simple_form's inflexibility (or my own lazyness
    # to type the form myself, without simple_form...). Yes,
    # it's dirty. Right now I just don't care...
    if params[:page]
      @search = params[:page][:search]
    else
      @search = params[:search]
    end
    begin
      @page = Page.find_by_root(@search)
      _cookies = @previous_searches
      _cookies.shift if (_cookies.length > 50)
      _cookies << @search_string
      _cookies.uniq!
      cookies[:previous_searches] = JSON.generate(_cookies)
    rescue
      flash.now[:alert] = 'Keine Suchergebnisse. Versuchen Sie die Eingabe einer Wurzel anstatt eines Wortes.'
    end
    respond_to do |format|
      format.html { @page ||= @book.pages.first_numbered; render :show }
      format.json { render json: {page: @page, previous_searches: @previous_searches.reverse} }
    end
  end

  private
    
  def set_book
    if params[:book] 
      book, language = params[:book].split('_')
      @book = Book.find_by(name: book, language: language)
    else
      @book = Book.first
    end
  end

  def init_session
    if cookies[:previous_searches].nil?
      @previous_searches = []
    else
      @previous_searches = JSON.parse(cookies[:previous_searches])
    end
  end
end
