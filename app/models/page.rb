class Page < ActiveRecord::Base
  belongs_to :book
  validates :number, :book_id, presence: true
  validates :number, uniqueness: {scope: :book_id}

  def self.first_numbered
    Page.find_by_number(1)
  end

  def self.find_by_root(search)
    # Re-implemented looking at Abdurahmans search algorithm,
    # which seems to consist of the following call stack:
    #
    # -> searchandgo()
    #     ^ do_search()
    #        ^ binarySearch()
    #           ^ suggest_completions()/load_book_texts()
    #              ^ make_suggestions()
    #
    # See indices/mawrid-app.js for reference. I'm skipping the
    # support for transliterations like Buckwater or similar,
    # mostly because I don't care for it all too much.
    #
    # Easiest and fastest: the root is already in the
    # list of roots for the current scope of book/page.
    logger.debug("*** find_by_root: searching for #{search.inspect}")
    unless page = self.find_by_last_root(search)
      #
      # No luck so far. To make things easier, substitute
      # hamzas for alifs and alif maksuras for yas (originally
      # do_search().
      search = search.gsub(/[إآٱأءﺀﺀﺁﺃﺅﺇﺉ]/, 'ا').gsub(/ﻯ/,'ﻱ')
      unless page = self.find_by_last_root(search)
        #
        # Still no luck. Time to modify the search string even
        # further. make_suggestions() seems to try and take a
        # guess at what other roots could be in the vincinity
        # of the searched-for root.
        unless page = self.most_likely_page(search)
          logger.debug("*** find_by_root: all search attempts turned out empty.")
          page = nil
        end
      end
    end
    return page 
  end

  def image_file
    "books/%s_%s/page_%04d.png" % [
      book.name, book.language, book.first_numbered_page+number-1]
  end

  def path
    "/#{book.full_name}/#{number}"
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
  def self.most_likely_page(search_value)
    pages = self.all
    first_possible_page = pages.first
    i = 0
    while pages[i].last_root <= search_value
      i += 1
      next if (pages[i+1] && (pages[i].last_root == pages[i+1].last_root))
    end
    pages[i]
  end
end
