class PagesController < ApplicationController
  before_filter :set_book

  def show
    @page = params[:number] ? Page.find(@book, params[:number]) : Page.first_with_content(@book)
  end
  
  def find
    @search_string = params[:search_string]
    begin
      @page = Page.find_by_search_string(@book, @search_string)
    rescue RuntimeError
      @page = Page.first_with_content(@book)
      flash.now[:alert] = "Keine Suchergebnisse"
    end
    render :show
  end
  
  private
  
  def set_book
    @book = Book.find_by_name(params[:name] || Book.first.name)
  end
end
