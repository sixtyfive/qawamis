class Page < ActiveRecord::Base
  belongs_to :book
  validates :number, :book_id, presence: true
  validates :number, uniqueness: {scope: :book_id}

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
  # See indices/mawrid-app.js for reference. I'm foregoing support for
  # transliterations like Buckwater or similar, mostly because I don't care
  # for them all too much. DMG is really quite good in terms of what it
  # offers for either having good disambiguation or having good legibility
  # for non-scholars, depending on publication. Honestly, if we could just
  # decide to standardize on it internationally, that might be good for the
  # community as a whole. Okay, I'm done ranting now.
  def self.find_by_root(query)
    return if query.nil?
    # Easiest and fastest: the root is already in the list of roots for the
    # current scope of book/page.
    logger.debug("*** find_by_root: searching for #{query.inspect}")
    unless page = self.find_by_last_root(query)
      # No luck so far. To make things easier, substitute hamzas for alifs
      # and alif maksuras for yas (originally do_search()).
      query = query.gsub(/[إآٱأءﺀﺀﺁﺃﺅﺇﺉ]/, 'ا').gsub(/ﻯ/,'ﻱ')
      unless page = self.find_by_last_root(query)
        # Still no luck. Time to modify the search string even further.
        # make_suggestions() seems to try and take a guess at what other
        # roots could be in the vincinity of the searched-for root.
        unless page = self.most_likely_page(query)
          logger.debug("*** find_by_root: all search attempts turned out empty.")
          return
        end
      end
    end
    page 
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

  private

  # Skip through all pages where the last root printed
  # on them is alphabetically lower or equal to the root
  # being searched for and then return the page after that.
  def self.most_likely_page(query)
    pages = self.all
    begin
      i = 0
      while pages[i].last_root <= query
        i += 1
        next if (pages[i+1] && (pages[i].last_root == pages[i+1].last_root))
      end
      pages[i]
    rescue
      # Pretty much the only thing that can cause this
      # branch to get executed is when the index is not
      # in strictly alphabetical order, which the tests
      # should prevent.
      first_possible_page = pages.first
      book = first_possible_page.book ? first_possible_page.book.name : 'unknown'
      logger.warn "  Warning: unable to find page in book '#{book}' for query '#{query}'! Test index!"
      first_possible_page
    end
  end
end
