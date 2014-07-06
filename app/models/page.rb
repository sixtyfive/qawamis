class Page
  include ActiveModel::Model
  attr_accessor :book_id, :number, :search_string

  # belongs_to :book

  def book
    Book.find(book_id)
  end

  # has_many :arabic_roots

  def arabic_roots
    ArabicRoot.where(start_page: number)
  end

  # attributes

  def image_file
    "books/%i/page_%04d.png" % [book_id, number]
  end

  # activerecord methods
  
  def previous
    number == 0 ? self : Page.new(book_id: book.id, number: number-1)
  end
  
  def next
    number == book.number_of_pages-1 ? self : Page.new(book_id: book.id, number: number+1)
  end

  def self.first(book)
    Page.new(book_id: book.id, number: 0)
  end

  def self.first_with_content(book)
    Page.new(book_id: book.id, number: book.first_content_page)
  end

  def self.find(book, id)
    id = id.to_i
    if (id > book.number_of_pages || id < 0)
      raise "Couldn't find Page with 'id'=#{id}"
    else
      Page.new(book_id: book.id, number: id)
    end
  end

  def self.find_by_search_string(book, string)
    page = Page.new(book_id: book.id, search_string: string)
    if page.number = number_for_arabic_root(string)
      return page
    else
      raise "Couldn't find Page with 'arabic_root'=#{string}"
    end
  end

  def self.last(book)
    Page.new(book_id: book.id, number: book.number_of_pages)
  end

  private
  
  def self.number_for_arabic_root(string)
    if r = ArabicRoot.find_by_search_string(string)
      return r.start_page
    end
  end
end
