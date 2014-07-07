class Book < ActiveRecord::Base
  has_many :arabic_roots

  # Poor man's "has_many :pages"
  def pages
    pages_ary = []
    (cover_page.id...last_page.id).each do |p|
      pages_ary << Page.new(book_id: id, id: p)
    end
    return pages_ary
  end

  def cover_page
    Page.new(book_id: id, id: 1 - first_numbered_page)
  end

  def first_page
    Page.new(book_id: id, id: 1)
  end

  def last_page
    Page.new(book_id: id, id: number_of_pages - first_numbered_page)
  end
end
