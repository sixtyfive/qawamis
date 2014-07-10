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
    # See mawrid/mawrid-app.js for reference. I'm skipping the
    # support for transliterations like Buckwater or similar,
    # mostly because I don't care for it all too much.
    #
    # Easiest and fastest: the root is already in the
    # list of roots for the current scope of book/page.
    logger.info("*** find_by_root (1): searching for #{search.inspect}")
    unless page = self.find_by_last_root(search)
      #
      # No luck so far. To make things easier, substitute
      # hamzas for alifs and alif maksuras for yas (originally
      # do_search().
      search = search.gsub(/[إآٱأءﺀﺀﺁﺃﺅﺇﺉ]/, 'ا').gsub(/ﻯ/,'ﻱ')
      logger.info("*** find_by_root (2): searching for #{search.inspect}")
      unless page = self.find_by_last_root(search)
        #
        # Still no luck. Time to modify the search string even
        # further. make_suggestions() seems to try and take a
        # guess at what other roots could be in the vincinity
        # of the searched-for root.
        if search = most_likely_closeby_root(search)
          logger.info("*** find_by_root (3): searching for #{search.inspect}")
          page = self.find_by_last_root(search)
        else
          logger.info("*** find_by_root: all search attempts turned out empty.")
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

  # Basically binarySearch() as found in Abdurahmans code.
  # He says its copyright holder to be Nicholas C. Zakas
  # who seems to have released his implementation under a
  # MIT license. I hope that's true. A big thank you to
  # both, Nicholas and Abdurahman!
  def self.most_likely_closeby_root(value)
    # Same as binarySearch()
    items = self.all
    # Array containing one item per every page, its content being the last root on that page.
    items = items.map {|p| p.last_root}
    # Like binarySearch()
    start_index = 0
    stop_index  = (items.count-1)
    middle = ((stop_index+start_index)/2).floor
    retval = 0
    # Instead of the loop_count-method for safeguarding against missing items.
    (start_index..stop_index).each {|i| items[i] ||= ''}
    # Should be safe to look up any value inside the items array now.
    # It seems to always take 10 iterations anyways. And I don't like
    # that it always comes up with /some/ results - that way, you can't
    # tell the user that you couldn't find anything.
    while (items[middle] != value && start_index < stop_index) do
      logger.info "*** most_likely_closeby_root: items[#{middle}]=#{items[middle].inspect}"
      stop_index  = middle-1 if value < items[middle]
      start_index = middle+1 if value > items[middle]
      break if (middle != 0 && value < items[middle] && value > items[middle-1])
      middle = ((stop_index + start_index)/2).floor
    end
    logger.info "*** most_likely_closeby_root: items[#{middle}]=#{items[middle].inspect} (corrected)"
    retval = 0 if middle == 0
    middle = items.length-1 if middle > items.length-1
    if (items[middle] == value)
      # This part never seems get any action...
      # Leaving the maximum number of iterations low.
      (1..8).each do |i|
        if (items[middle-i] != value)
          retval = middle-i+1
          break
        end
      end
    else
      if value > items[middle] && value.length == 1
        retval = middle+1
      else
        retval = middle
      end
    end
    # No idea what is going on above, but it's pretty darn
    # cool and seems to yield very desirable results :-)
    logger.info "*** most_likely_closeby_root: items[#{retval}]=#{items[retval].inspect} (while searching for #{value.inspect})"
    return items[retval].empty? ? nil : items[retval]
  end
end
