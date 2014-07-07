class Page
  include ActiveModel::Model
  attr_accessor :id, :book_id, :search_string

  # associations

  def book; @book || @book = Book.find(book_id); end      # belongs_to :book
  def arabic_roots; ArabicRoot.where(start_page: id); end # has_many :arabic_roots

  # attributes

  def image_file
    "books/%i/page_%04d.png" % [book.id, id+first_numbered-1] # The image files begin at 0.
  end

  # activerecord methods
  
  def previous
    id <= first_real ? self : Page.new(book_id: book.id, id: id-1)
  end
  
  def next
    id >= last_real ? self : Page.new(book_id: book.id, id: id+1)
  end

  def self.first(_book)
    first_real = 1-_book.first_numbered_page
    Page.new(book_id: _book.id, id: first_real) 
  end

  def self.first_with_content(_book)
    Page.new(book_id: _book.id, id: 1)
  end

  def self.find(_book, _id)
    _id = _id.to_i
    first_real = 1-_book.first_numbered_page
    last_real = _book.number_of_pages-_book.first_numbered_page
    if (_id < first_real || _id > last_real)
      raise "Couldn't find Page with 'id'=#{_id}"
    else
      Page.new(book_id: _book.id, id: _id)
    end
  end

  def self.find_by_search_string(_book, string)
    page = Page.new(book_id: _book.id, search_string: string)
    if page.id = number_for_arabic_root(string)
      return page
    else
      raise "Couldn't find Page with 'arabic_root'=#{string}"
    end
  end

  def self.last(_book)
    last_real = _book.number_of_pages-_book.first_numbered_page
    Page.new(book_id: _book.id, id: last_real)
  end

  private
  
  def self.number_for_arabic_root(string)
    r.start_page if r = ArabicRoot.find_by_search_string(string)
  end
  
  def first_real
    1-book.first_numbered_page
  end

  def first_numbered
    book.first_numbered_page
  end

  def last_real
    book.number_of_pages - book.first_numbered_page
  end
end
