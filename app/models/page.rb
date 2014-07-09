class Page < ActiveRecord::Base
  belongs_to :book
  validates :number, :book_id, presence: true
  validates :number, uniqueness: {scope: :book_id}

  def image_file
    "books/%s_%s/page_%04d.png" % [
      book.name, book.language, book.first_numbered_page+number-1]
  end

  def self.first_numbered
    Page.find_by_number(1)
  end

  def self.find_by_root(search)
    # TODO: Implement full search algorithm.
    Page.find_by_last_root(search)
  end

  def path
    "/#{book.full_name}/#{number}"
  end

  def previous
    Page.where('pages.number < ?', number).order('pages.number DESC').first || self
  end

  def next
    Page.where('pages.number > ?', number).order('pages.number ASC').first || self
  end

  def js_attributes
    {
      path: path,
      first_page: 1-book.first_numbered_page,
      last_page: book.pages.count-book.first_numbered_page,
      nosearchresults_message: I18n.t(:nosearchresults),
      page: I18n.t(:page),
      book: book.full_name
    }
  end
end
