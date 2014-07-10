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
    logger.warn("*** find_by_root: searching for [#{search}]")
    unless page = self.find_by_last_root(search)
      #
      # No luck so far. To make things easier, substitute
      # hamzas for alifs and alif maksuras for yas (originally
      # do_search().
      search = search.gsub(/[إآٱأءﺀﺀﺁﺃﺅﺇﺉ]/, 'ا').gsub(/ﻯ/,'ﻱ')
      logger.warn("*** find_by_root: searching for [#{search}]")
      unless page = self.find_by_last_root(search)
        #
        # Still no luck. Time to modify the search string even
        # further. make_suggestions() seems to try and take a
        # guess at what other roots could be in the vincinity
        # of the searched-for root.
        search = most_likely_closeby_root(search)
        logger.warn("*** find_by_root: searching for [#{search}]")
        page = self.find_by_last_root(search)
      end
    end
    return page
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

  def js_attributes
    {
      path: path,
      first_page: 1-book.first_numbered_page,
      last_page: book.pages.count-book.first_numbered_page,
      nosearchresults_message: I18n.t(:nosearchresults),
      page: I18n.t(:page),
      book: book.full_name,
      book_id: book.id,
      last_root: last_root
    }
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
    # Leaving out loop_count for now; I think Ruby should
    # saveguard against an infinite loop here.
    while (items[middle] != value && start_index < stop_index) do
      stop_index  = middle-1 if value < items[middle]
      start_index = middle+1 if value > items[middle]
      break if (middle != 0 && value < items[middle] && value > items[middle-1])
      middle = ((stop_index + start_index)/2).floor
    end
    logger.warn "*** most_likely_closeby_root: recalculated middle=#{middle}"
    retval = 0 if middle == 0
    middle = items.length-1 if middle > items.length-1
    if (items[middle] == value)
      (1..32).each do |i|
        if (items[middle-1] != value)
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
    logger.warn "*** most_likely_closeby_root: items[#{retval}]=[#{items[retval]}] (while searching for [#{value}])"
    return items[retval]
  end
end
