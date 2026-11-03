require 'test_helper'

# Integration tests for the externally observable side of
# PagesController#show where PagesController#compute_root_warning is the
# decision point:
#
#   - Same-book navigation (params[:book_slug] matches the cookie's book)
#     never warns; the requested page renders as 200 OK.
#   - Cross-book navigation whose prev_root is plausibly in the target
#     book (i.e. Book#could_contain? accepts it) does not warn; the
#     target book's page renders as 200 OK.
#   - Cross-book navigation whose prev_root is out of range in the
#     target book does warn; the controller redirects (302) back to the
#     user's previously viewed book/page, signalling via flash that the
#     entry isn't in the selected book.
#
# This is the integration-level mirror of the older
# PagesController#compute_root_warning property test, but it exercises
# the actual HTTP path instead of poking at a private helper. If the
# sidebar's lighter-colour indicator and the controller's first-click
# warning redirect disagree on ANY (root, book) combination, that is
# precisely the kind of UX inconsistency this test guards against.
class PagesTest < ActionDispatch::IntegrationTest
  # Arabic roots we walk against every book in the corpus. Each is
  # chosen to exercise a different decision branch:
  #
  #   ابر - common, present in many books
  #   ابل - similar wide coverage
  #   ارب - often appears as a page's last_root exactly
  #   قمس - Lisān al-ʿArab only, very narrow match
  #   أبغ - exercises the alef-with-hamza normalisation path
  EXAMPLE_ROOTS = [
    "\u0627\u0628\u0631", # ابر
    "\u0627\u0628\u0644", # ابل
    "\u0627\u0631\u0628", # ارب
    "\u0642\u0645\u0633", # قمس
    "\u0623\u0628\u063A", # أبغ
  ].freeze

  # The book used as the "previously viewed" book in the test browser's
  # cookie state. The seed corpus always carries it; we attach synthetic
  # Page rows to it whose only job is to carry arbitrary last_root values
  # so we can sweep the (root, book) product without being constrained
  # by which roots the seed happens to ship as last_roots.
  PREV_BOOK_NAME     = 'hw4'
  PREV_BOOK_LANGUAGE = 'en'

  setup do
    Rails.application.load_seed if Book.count == 0
    @prev_book = Book.find_by(name: PREV_BOOK_NAME, language: PREV_BOOK_LANGUAGE) or
      flunk("Previous-book fixture missing: #{PREV_BOOK_NAME}_#{PREV_BOOK_LANGUAGE}")
  end

  # Normalise alef-with-hamza / ya / ى variants to bare alef and,
  # so a query like "أبر" sorts into the same slot as "ابر". Pure
  # byte-level matching against book.first_root/last_root would
  # otherwise flag two visually-equal-but-byte-different roots as if
  # they were different.
  def normalize(root_str)
    root_str
      .gsub(/[\u0623\u0625\u0622\u0627]/, "\u0627")
      .gsub(/[\u0649\u064A]/,   "\u064A")
  end

  # Create a real Page on @prev_book whose last_root is exactly
  # root_str. PagesController#prev_page_if_known looks pages up by
  # Page.find_by(book:, number:), so the test browser's cookies must
  # point at a persisted Page row with a known number -- a Struct stub
  # doesn't survive the actual model lookup.
  def install_prev_page(root_str)
    max_number = @prev_book.pages.maximum(:number) || 0
    @prev_book.pages.create!(number: max_number + 1_000_000, last_root: root_str)
  end

  # Issue a #show request with the cookie state pointing at
  # @prev_book/<synthetic page>, target `target_book` at any numbered
  # page, and report whether the controller's warning branch fired
  # (302 back to /@prev_book/<synthetic page>).
  def warned?(target_book, prev_root)
    prev_page = install_prev_page(prev_root)
    cookies[:book_slug] = @prev_book.slug
    cookies[:page]      = prev_page.number.to_s

    get "/#{target_book.slug}/1"

    response.redirect? && URI.parse(response.location).path == "/#{@prev_book.slug}/#{prev_page.number}"
  end

  test "show's warning redirect agrees with the book's stored alphabet range for every (example root, book) pair" do
    flunk 'Test book setup mis-seeded; expected >= 10 books loaded' if Book.count < 10

    mismatches = []
    Book.all.each do |target_book|
      # compute_root_warning short-circuits when prev_page.book == target_book
      # (same-book navigation is unconditional no-warning). Skip that case in
      # the property sweep.
      next if target_book.slug == @prev_book.slug

      EXAMPLE_ROOTS.each do |root_str|
        actual = warned?(target_book, root_str)
        expected =
          if target_book.first_root.blank? || target_book.last_root.blank?
            false
          else
            n = normalize(root_str)
            n < target_book.first_root.to_s || n > target_book.last_root.to_s
          end

        next if actual == expected

        mismatches << [
          root_str, target_book.slug,
          "first_root=#{target_book.first_root.inspect}",
          "last_root=#{target_book.last_root.inspect}",
          "expected=#{expected.inspect}",
          "actual=#{actual.inspect}"
        ].join(' ')
      end
    end

    assert_empty mismatches,
                 "show's warning redirect disagreed with the alphabetic range check on " \
                 "#{mismatches.size} (root, book) pair(s):\n  - " + mismatches.join("\n  - ")
  end

  test "show locks in the now-stable behaviour for the reported scenarios" do
    cases = {
      ['ابر', 'la_ar']  => false, # la_ar covers ابر
      ['ابر', 'ls_en']  => true,  # ls_en starts at ق, so ابر is out of range
      ['قمس', 'hw5_de'] => false, # hw5_de spans ق..يونيو
      ['قمس', 'la_ar']  => false, # la_ar has قمس as an exact last_root
      ['قمس', 'ls_en']  => false, # ls_en starts at ق and covers قمس's range
      ['اب',  'amj_ar'] => true,  # amj_ar starts at ابر, so اب is out of range
      ['أبط', 'hw5_de'] => false, # hamza variant sorts into ابد..يونيو
    }
    cases.each do |(root_str, slug), expected|
      name, language = slug.split('_', 2)
      book = Book.find_by(name: name, language: language) or
        flunk("Fixture book missing: #{slug}")
      actual = warned?(book, root_str)
      assert_equal expected, actual,
                   "root=#{root_str.inspect} book=#{slug}: " \
                   "expected #{expected ? 'warning redirect' : 'no warning (200 OK)'}, " \
                   "got #{actual ? "redirect to #{response.location.inspect}" : 'no redirect'}"
    end
  end

  test "show does not warn for prefix-sharing June-like books when prev is hw5_de page 1452 (يونيو)" do
    # The concrete bug scenario: hw5_de's last page (1452) ends in the
    # root "يونيو" (يون + ي + و -> June). Several other books index a
    # June-related entry on their last page with a slightly different
    # spelling -- hw3_en has "يونو", maw_en has "يويو", mgf_en has
    # "يوم", br_en and pr_en have "يونس", vq_en has "يون". Under pure
    # alphabetic comparison these last_roots all sort BELOW "يونيو" so
    # the previous code wrongly triggered the "root not in selected
    # book" warning when switching into any of them. The
    # open-ended-last-page rule in Book#could_contain? turns all of
    # those off (they share a 2+ character prefix with the query) while
    # leaving truly far-away books like vi_en ("يمم"), ll_en ("يلب")
    # and ls_en ("يقن") to still warn.
    hw5_de = Book.find_by(name: 'hw5', language: 'de') or flunk('hw5_de fixture missing')
    prev_root = "\u064A\u0648\u0646\u064A\u0648" # يونيو -- last root of hw5_de page 1452
    # Mirror that concrete page with a synthetic one so the cookie
    # lookup actually finds something. Real page numbers in the seed
    # corpus are bounded; +1_000_000 keeps us safely out of the way.
    prev_page = hw5_de.pages.create!(
      number: (hw5_de.pages.maximum(:number) || 0) + 1_000_000,
      last_root: prev_root,
    )

    expected_redirects = {
      'hw4_en' => false, # exact last_root match (1315's last_root is "يونيو")
      'hw3_en' => false, # last_root "يونو" -- same neighbourhood, open-ended last page holds the same June entry
      'maw_en' => false, # last_root "يويو" -- same prefix "يو"
      'mgf_en' => false, # last_root "يوم"  -- prefix "يو"
      'br_en'  => false, # last_root "يونس"  -- prefix "يون"
      'pr_en'  => false, # last_root "يونس"  -- prefix "يون"
      'vq_en'  => false, # last_root "يون"   -- prefix "يون"
      'vi_en'  => true,  # last_root "يمم"   -- different prefix; warning expected
      'll_en'  => true,  # last_root "يلب"   -- different prefix; warning expected
      'ls_en'  => true   # last_root "يقن"   -- different prefix; warning expected
    }

    expected_redirects.each do |slug, expected|
      name, language = slug.split('_', 2)
      book = Book.find_by(name: name, language: language) or flunk("Fixture book missing: #{slug}")
      cookies[:book_slug] = hw5_de.slug
      cookies[:page]      = prev_page.number.to_s

      get "/#{book.slug}/1"
      got = response.redirect? && URI.parse(response.location).path == "/#{hw5_de.slug}/#{prev_page.number}"
      assert_equal expected, got,
                   "root='#{prev_root}' book=#{slug} (last_root=#{book.last_root.inspect}): " \
                   "warning_redirect=#{got.inspect}, expected #{expected.inspect}"
    end
  end
end
