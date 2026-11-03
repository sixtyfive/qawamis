class Book < ActiveRecord::Base
  has_many :pages, dependent: :destroy
  validates :name, :language, :first_numbered_page, presence: true
  validates :name, uniqueness: {scope: :language}
  default_scope {order('id ASC')}
  
  def cover_page
    pages.first
  end

  def first_page
    pages.first_numbered
  end

  def last_page
    pages.last
  end

  # The book's stored alphabet range, taking the first and last nonfiction
  # last_root. Index files sometimes end in trailing blank lines which
  # produce pages with an empty last_root — those don't represent actual
  # content and would otherwise pin the range to "" (making every
  # alphabetically-placed root look out of range, or the inverse). Use
  # these when bounding or comparing roots against the book.
  def first_root
    pages.where.not(last_root: [nil, '']).first&.last_root
  end

  def last_root
    pages.where.not(last_root: [nil, '']).last&.last_root
  end

  # Whether `root_str` could plausibly appear on some page of this book.
  #
  # The page index stores exactly one last_root per page, so any check of
  # the form "is this root in this book?" is necessarily an approximation.
  # We treat two cases as "could contain":
  #
  #   1. `root_str` is alphabetically within the indexed range
  #      [first_root, last_root] — the strict check the sidebar JS uses
  #      and what `compute_root_warning` used to do.
  #   2. `root_str` is past `last_root`. The very last page is open-ended
  #      (the index only records one last_root per page, so the last page
  #      could carry entries beyond its indexed root). We only declare this
  #      a hit when `root_str` shares a 2+ character prefix with
  #      `last_root`, i.e. it's in the same alphabet neighbourhood. This
  #      catches the reported close-miss case: `hw5_de` page 1452 ends in
  #      "يونيو" but `hw3_en`'s last page ends in "يونو" — the two are
  #      June-related entries whose indexed spellings differ by a single
  #      character; without this branch the sidebar would land on the
  #      cover page and `compute_root_warning` would ask the user to
  #      confirm a switch to a book that almost certainly has the entry.
  #
  # Only the query is normalised; the book's stored first/last_root keep
  # their byte-faithful spelling so byte-wise comparisons between "ابر"
  # (query) and "أبي" (pr_en's first page) still place them in the same
  # range as before.
  def could_contain?(root_str)
    return false if root_str.blank?
    return false if first_root.blank? || last_root.blank?

    norm_root = Book.normalize_root(root_str)

    return true if norm_root >= first_root.to_s && norm_root <= last_root.to_s

    # Open-ended last-page escape hatch.
    return false if norm_root.length < 2 || last_root.to_s.length < 2
    norm_root[0, 2] == last_root.to_s[0, 2]
  end

  # Collapse alef-with-hamza variants to bare alef and ي/ى to ي so a query
  # like "أبر" sorts into the same slot as "ابر" when compared against the
  # indexed first/last_root bytes.
  def self.normalize_root(root_str)
    root_str.to_s
      .gsub(/[\u0623\u0625\u0622\u0627\u0671\u0621\u0624\u0626]/, "\u0627")
      .gsub(/[\u0649\u064A]/, "\u064A")
  end

  def slug
    "#{name}_#{language}"
  end

  def human_name
    I18n.t("books.#{slug}")
  end

  def serialize
    self.attributes.merge({
      cover_page: self.cover_page.number,
      first_page: self.first_page.number,
      last_page:  self.last_page.number,
      slug:       self.slug,
      human_name: self.human_name
    })
  end

  def self.default
    Book.find_by(name: 'hw4', language: 'en')
  end
end
