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

      # Latin-script (Arabizi) input is transliterated into a ranked list of
      # plausible Arabic roots; native Arabic input is searched as-is. Either
      # way we end up with an ordered list of root strings to try.
      queries = search_queries(@query)

      # 1. Best exact hit in the current book, trying candidates in order.
      queries.each do |q|
        break if @page = exact_root_search(@book, q)
      end

      # 2. Otherwise the best exact hit in any other book.
      unless @page
        catch(:found) do
          queries.each do |q|
            Book.all.each do |book|
              next if book == @book
              if page = exact_root_search(book, q)
                @book = book
                @page = page
                flash[:notice] = t(:nosearchresults_in_selectedbook, book: @book.human_name)
                throw :found
              end
            end
          end
        end
      end

      # 3. Nothing exact anywhere: fall back to the nearest entry in the
      #    selected book for the most plausible candidate.
      unless @page
        @page = @book.pages.find_by_root(queries.first)
        flash[:warn] = t(:nosearchresults)
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

  # The ordered list of Arabic root strings to try for a search term. For
  # Latin-script (Arabizi) input this is the ranked transliteration; for Arabic
  # input it is just the term itself. Falls back to the raw query if the
  # transliterator yields nothing usable.
  def search_queries(query)
    if Arabizi.latin?(query)
      candidates = Arabizi.root_candidates(query)
      candidates.any? ? candidates : [query]
    else
      [query]
    end
  end

  # An exact root lookup in one book, also trying the alef/hamza-normalised
  # form the way find_by_root does. Returns the page or nil.
  def exact_root_search(book, query)
    page = book.pages.find_by_last_root(query)
    unless page
      simplified_query = query.gsub(/[إآٱأءﺀﺀﺁﺃﺅﺇﺉ]/, 'ا').gsub(/ﻯ/, 'ﻱ')
      page = book.pages.find_by_last_root(simplified_query)
    end
    page
  end

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
