class PagesController < ApplicationController
  before_action :init_cookies, :set_books
  before_action :set_book, except: [:index]

  # GET /
  def index
    redirect_to("/#{Book.default.name}_#{Book.default.language}/1")
  end

  # GET /:book_slug/:page
  def show
    if cookies[:book_slug] && cookies[:book_slug] != @book.slug
      prev_book_name, prev_book_lang = cookies[:book_slug].split('_')
      prev_book = Book.find_by(name: prev_book_name, language: prev_book_lang)
      if prev_book && prev_page = Page.find_by(book: prev_book, number: cookies[:page])
        unless @book.pages.find_by_last_root(prev_page.last_root) || 
               @book.pages.find_by_last_root(prev_page.last_root.gsub(/[إآٱأءﺀﺀﺁﺃﺅﺇﺉ]/, 'ا').gsub(/ﻯ/,'ﻱ'))
          flash.now[:notice] = t(:nosuchentry_in_selectedbook)
        end
      end
    end

    if @page = Page.find_by(book: @book, number: params[:page])
      cookies[:book_slug] = {value: @book.slug, expires: 1.year.from_now}
      cookies[:page] = {value: @page.number, expires: 1.year.from_now}
    end
    respond_to do |format|
      format.html do
        @page ||= @book.pages.first_numbered
      end
      format.json do
        flash_msg = flash.first
        flash.discard
        render(json: {book: @page.book.serialize, page: @page.serialize, flash: flash_msg}) if @page
      end
    end
  end

  # GET /:query
  # POST /search
  def find
    @query = params[:query]
    if @query.number?
      @page = @book.pages.find_by_number(@query)
    else
      update_search_history
      
      # 1. Search in current book
      @page = @book.pages.find_by_last_root(@query)
      unless @page
        simplified_query = @query.gsub(/[إآٱأءﺀﺀﺁﺃﺅﺇﺉ]/, 'ا').gsub(/ﻯ/,'ﻱ')
        @page = @book.pages.find_by_last_root(simplified_query)
      end
      
      if @page
        # Found exactly in current book
      else
        # 2. Try to find in another book
        other_page = nil
        other_book = nil
        Book.all.each do |book|
          next if book == @book
          other_page = book.pages.find_by_last_root(@query)
          unless other_page
            simplified_query = @query.gsub(/[إآٱأءﺀﺀﺁﺃﺅﺇﺉ]/, 'ا').gsub(/ﻯ/,'ﻱ')
            other_page = book.pages.find_by_last_root(simplified_query)
          end
          if other_page
            other_book = book
            break
          end
        end
        
        if other_page
          @book = other_book
          @page = other_page
          flash[:notice] = t(:nosearchresults_in_selectedbook, book: @book.human_name)
        else
          # 3. Not found in any book, fall back to nearest in selected book
          @page = @book.pages.find_by_root(@query)
          flash[:warn] = t(:nosearchresults)
        end
      end
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
