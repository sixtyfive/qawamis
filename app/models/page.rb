class Page
  include ActiveModel::Model
  attr_accessor :book_id, :number

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

  def self.first(book)
    Page.new(book_id: book.id, number: 0)
  end

  def self.first_with_content(book)
    Page.new(book_id: book.id, number: book.first_content_page)
  end

  def self.find(book, id)
    if (id > book.number_of_pages || id < 0)
      raise "Couldn't find Page with 'id'=#{id}"
    else
      Page.new(book_id: book.id, number: id)
    end
  end

  def self.find_by_arabic_root(book, search_string)
    # First, remove anything that might get in the way.
    search_string = remove_vocalisation_from_arabic_string(search_string)
    if r = ArabicRoot.find_by_name(search_string)
      # The easiest case: the search string matches an existing entry point precisely.
      # No further processing needs to be done.
      return Page.find(book, r.start_page)
    else
      # No entry point has been found with the search string as-is. 
      # The remaining possibilities:
      # - user has entered three radicals
      # - user has entered four radicals
      # - user has entered a word
      # - user has entered something nonsensical
      if r = ArabicRoot.find_by_name(simplify_hamzas_in_arabic_string(search_string))
        # The latter case is the easiest, as only extraneous hamzas need to be stripped
        # from the first letter and inner-word hamzas as well as hamzas on the last letter
        # need to be reduced to free-standing ones.
        return Page.find(book, r.start_page)
      elsif r = ArabicRoot.find_by_name(extract_root_from_arabic_string(search_string))
        # The only thing left to try is to make an attempt at extracting the root ourselves.
        return Page.find(book, r.start_page)
      else
        raise "Couldn't find Page with 'arabic_root'=#{search_string}"
      end
    end
  end

  def self.last(book)
    Page.new(book_id: book.id, number: book.number_of_pages)
  end

  private

  def remove_vocalisation_from_arabic_string(string)
    # TODO: Implement me!
    string
  end

  def simplify_hamzas_in_arabic_string(string)
    # TODO: Implement me!
    string
  end

  def extract_root_from_arabic_string(string)
    # TODO: Implement me!
    string
  end
end
