class Page < ActiveRecord::Base
  belongs_to :book
  validates :number, :book_id, presence: true
  validates :number, uniqueness: {scope: :book_id}

  # As in, the page that has number 1 printed on it
  def self.first_numbered
    find_by(number: 1)
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
    return page if page

    simplified_query = query.gsub(/[إآٱأءﺀﺀﺁﺃﺅﺇﺉ]/, 'ا').gsub(/ﻯ/,'ﻱ')
    page = find_by_last_root(simplified_query)
    return page if page

    page = where('last_root >= ?', query).order(:last_root).first
    return page if page

    # Query is alphabetically past every indexed last_root in this book.
    # The very last page is open-ended — the page index records exactly
    # one last_root per page, so the last page may carry entries beyond
    # its indexed root. Mirror Book#could_contain? and treat the last
    # page as a valid landing spot when its indexed last_root shares a
    # 2+ char prefix with the query (e.g. viewing `hw5_de` page 1452
    # last_root "يونيو" and clicking `hw3_en`, whose last page ends at
    # "يونو"). The relation chain keeps the lookup scoped to the caller's
    # book — bare `last` here would fall back to the globally-last Page,
    # which is what we'd see if a page-having relation proxy isn't set up.
    candidate = where.not(last_root: [nil, '']).order(last_root: :desc).first
    if candidate &&
       query.length >= 2 &&
       candidate.last_root.to_s.length >= 2 &&
       query[0, 2] == candidate.last_root.to_s[0, 2]
      candidate
    else
      first_numbered
    end
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

  # The page immediately before this one in the book, or nil when this is
  # already the lowest-numbered content page. Used by the quicknav to show
  # the alphabet range covered by the currently displayed page.
  def previous_page
    self.book.pages.where(number: number - 1).first
  end

  def serialize
    self.attributes.merge({
      image_file:           self.image_file,
      path:                 self.path,
      previous:             self.previous.number,
      next:                 self.next.number,
      previous_last_root:   self.previous_page&.last_root
    })
  end
end
