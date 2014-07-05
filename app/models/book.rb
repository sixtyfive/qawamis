class Book < ActiveRecord::Base
  has_many :arabic_roots

  # has_many :pages

  def pages
    pages_ary = []
    (0...self.number_of_pages).each do |p|
      pages_ary << Page.new(book_id: self.id, number: p)
    end
    return pages_ary
  end
end
