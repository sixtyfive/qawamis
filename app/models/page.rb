class Page < ActiveRecord::Base
  belongs_to :book
  validates :number, :book_id, presence: true
  validates :number, uniqueness: {scope: :book_id}

  # As in, the page that has number 1 printed on it
  def self.first_numbered
    Page.find_by_number(1)
  end

  # Re-implemented while looking at Abdurahmans search algorithm, which seems
  # to consist of the following call stack:
  #
  # -> searchandgo()
  #     ^ do_search()
  #        ^ binarySearch()
  #           ^ suggest_completions()/load_book_texts()
  #              ^ make_suggestions()
  #
  # See indices/mawrid-app.js for reference.
  # I'm foregoing support for transliterations for the moment.
  def self.find_by_root(query)
    return false if query.blank?
    page = find_by_last_root(query)
    unless page
      simplified_query = query.gsub(/[إآٱأءﺀﺀﺁﺃﺅﺇﺉ]/, 'ا').gsub(/ﻯ/,'ﻱ')
      page = find_by_last_root(simplified_query)
      unless page
        page = where('last_root >= ?', query).order(:last_root).first
        unless page
          page = first_numbered
        end
      end
    end
    return page
  end

  def image_file
    "books/%s_%s/page_%04d.png" % [book.name, book.language, book.first_numbered_page+number-1]
  end

  def path
    "/#{book.slug}/#{number}"
  end

  def previous
    self.book.pages.where('pages.number < ?', number).order('pages.number DESC').first || self
  end

  def next
    self.book.pages.where('pages.number > ?', number).order('pages.number ASC').first || self
  end

  def serialize
    self.attributes.merge({
      image_file: self.image_file,
      path:       self.path,
      previous:   self.previous.number,
      next:       self.next.number
    })
  end
end
