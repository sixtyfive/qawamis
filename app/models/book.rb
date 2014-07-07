class Book < ActiveRecord::Base
  has_many :arabic_roots

  # Poor man's "has_many :pages"
  def pages
    pages_ary = []
    (first_page...last_page).each do |p|
      pages_ary << Page.new(book_id: id, id: p)
    end
    return pages_ary
  end

  def first_page
    0 - first_numbered_page
  end

  def last_page
    number_of_pages - first_numbered_page
  end
end
