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
      session[:previous_searches].shift if session[:previous_searches].length > 50
      session[:previous_searches] << @search_string
      session[:previous_searches].uniq!
    rescue RuntimeError
      flash.now[:alert] = "Keine Suchergebnisse. Versuchen Sie die Eingabe einer Wurzel anstelle eines Wortes."
    end
    respond_to do |format|
      format.html { @page ||= Page.first_with_content(@book); render :show }
      format.json { render json: {page: @page, previous_searches: session[:previous_searches].reverse} }
    end
  end
  
  private
  
  def set_book
    @book = Book.find_by_name(params[:book_name] || Book.first.name)
  end

  def initialize_session
    @previous_searches = session[:previous_searches] ||= []
  end
end
