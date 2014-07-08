class PagesController < ApplicationController
  before_filter :set_book, :initialize_session

  def show
    @page = Page.find(@book, params[:page_id] || 1)
  rescue
    @book = Book.first                     # To guard against nonexisting books.
    @page = Page.first_with_content(@book) # To guard against nonexisting pages.
  end
  
  def find
    @search_string = params[:search_string] || params[:page][:search_string] # Dirty, I know.
    begin
      @page = Page.find_by_search_string(@book, @search_string)
      _cookies = @previous_searches
      _cookies.shift if (_cookies.length > 50)
      _cookies << @search_string
      _cookies.uniq!
      cookies[:previous_searches] = JSON.generate(_cookies)
    rescue RuntimeError
      flash.now[:alert] = "Keine Suchergebnisse. Versuchen Sie die Eingabe einer Wurzel anstelle eines Wortes."
    end
    respond_to do |format|
      format.html { @page ||= Page.first_with_content(@book); render :show }
      format.json { render json: {page: @page, previous_searches: @previous_searches.reverse} }
    end
  end
  
  private
  
  def set_book
    @book = Book.find_by_name(params[:book_name] || Book.first.name)
  end

  def initialize_session
    if cookies[:previous_searches].nil?
      @previous_searches = []
    else
      @previous_searches = JSON.parse(cookies[:previous_searches])
    end
  end
end
