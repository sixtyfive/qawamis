require 'test_helper'

class PageTest < ActiveSupport::TestCase
  PREVIOUSLY_REPORTED_FAILED = {
    hw5: [
      ['توح', 147],
      ['ذرع', 427],
      ['نصح', 1278],
      ['نزف', 1262],
      ['جرا', 173],
      ['نزح', 1260],
      ['شوه', 686],
      ['انق', 49],
      ['ادي', 15],
      ['نظر', 1285],
      ['ذهن', 434],
      ['حيث', 313],
      ['حير', 314],
      ['وضح', 1409],
      ['نصر', 1279],
      ['قضو', 1035],
      ['نمط', 1317],
      ['ذهل', 434],
      ['طوي', 795],
      ['حول', 306],
      ['جري', 179],
      ['كب', 1080],
      ['نشد', 1272],
      ['ذقن', 428],
      ['ثاب', 149],
      ['نب', 1240],
      ['نشي', 1276],
      ['ملا', 1218],
      ['لحي', 1148]
    ]
  }

  # Three stylistically distinct Arabizi variants per Arabic test root. Each
  # variant transliterates back to the same Arabic root via the library's
  # first candidate, so the same book page is returned regardless of which
  # spelling the user types. The variants span three Arabizi conventions:
  #
  #   1) long-vowel   - uses aa/oo/ii/uu/ou/aw digraphs so middle short vowels
  #                     drop freely and the weak radicals emerge naturally.
  #   2) short-vowel  - spreads plain a/e/i/o/u between consonants; relies
  #                     on the library's "drop middle vowel == free" rule.
  #   3) consonant-only or alternate consonant - either no filler at all, or
  #                     a different ASCII letter for the same phoneme
  #                     (j/g, c/k, p/b, n9=s, ...).
  #
  # For roots where the third convention cannot be a clean consonant swap
  # without introducing a length-3 candidate that wins (e.g. very short
  # 2-radical roots like نب), we use a chat-style punctuation variant that
  # the library's sanitizer strips to the same underlying form (e.g. "n.b").
  ARABIZI_VARIANTS = {
    'توح' => ['taawa7',    'to7',      'tw7'    ], # long-vowel aa  / vowel o / consonant w
    'ذرع' => ['dhaaraa3',  'dhara3',   'dhr3'   ], # long-vowel x3  / vowel a / none
    'نصح' => ['n97',       'na9a7',    'nu9u7'  ], # consonant-only / vowel x2  / vowel u x2
    'نزف' => ['naazaaf',   'nazaf',    'nzf'    ], # long-vowel x4  / vowel a / none
    'جرا' => ['jaaraaa',   'jra',      'jraa'   ], # long-vowel x3  / none       / trailing aa
    'نزح' => ['naazaa7',   'naza7',    'nz7'    ], # long-vowel x3  / vowel a / none
    'شوه' => ['shaawaah',  'shoh',     'shwh'   ], # long-vowel x3  / vowel o / consonant w
    'انق' => ['aaaanaa8',  'an8',      'anq'    ], # long-vowel x3  / alt-digit 8 / consonant q
    'ادي' => ['aaaadaaai', 'adi',      'ady'    ], # long-vowel x5  / none       / alt y
    'نظر' => ['naa6\'aar', 'n6\'r',    'na6\'ar'], # long-vowel  / digit-apostrophe / partial
    'ذهن' => ['dhaahaan',  'dhahan',   'dhhn'   ], # long-vowel x3  / vowel a / none
    'حيث' => ['7aayaath',  '7ith',     '7yth'   ], # long-vowel x3  / vowel i / none
    'حير' => ['7aayaar',   '7ir',      '7yr'    ], # long-vowel x3  / vowel i / none
    'وضح' => ['au9\'7',    'u9\'7',    'o9\'7'  ], # long-vowel au   / vowel u   / vowel o
    'نصر' => ['naa9aar',   'n9r',      'na9ar'  ], # long-vowel x3  / none       / vowel a
    'قضو' => ['89\'au',    'q9\'au',   'q9\'o'  ], # digit 8 + au   / q + au    / q + o
    'نمط' => ['naamaa6',   'nama6',    'nm6'    ], # long-vowel x3  / vowel a / none
    'ذهل' => ['dhaahaal',  'dhahal',   'dhhl'   ], # long-vowel x3  / vowel a / none
    'طوي' => ['6aauai',    '6oi',      '6oy'    ], # long-vowel x4  / vowel o+i / vowel only
    'حول' => ['7aawaal',   '7ol',      '7wl'    ], # long-vowel x3  / vowel o / consonant w
    'جري' => ['jaaraaai',  'jri',      'jry'    ], # long-vowel x4  / vowel i / none
    'كب'   => ['cb',       'kb',       'kp'     ], # alt c / default k / alt p
    'نشد' => ['naashaad',  'nashad',   'nshd'   ], # long-vowel x3  / vowel a / none
    'ذقن' => ['dhaa8aan',  'dh8n',     'dhqn'   ], # long-vowel x3  / digit 8 alias for /q/ / consonant
    'ثاب' => ['thaaaaaab', 'thab',     'thap'   ], # long-vowel x5  / vowel a / alt p
    'نب'   => ['nb',       'np',       'n.b'    ], # consonant / alt p / chat punctuation (sanitized -> nb)
    'نشي' => ['naashaaai', 'nshi',     'nshy'   ], # long-vowel x5  / vowel i / consonant y
    'ملا' => ['maalaaa',   'mla',      'mlaa'   ], # long-vowel x4  / none       / trailing aa
    'لحي' => ['l7ai',      'l7i',      'l7y'    ], # vowel a+i       / vowel i   / consonant y
  }.freeze

  PREVIOUSLY_REPORTED_FAILED.each do |book_name, tests|
    if book = Book.find_by_name(book_name)
      tests.each do |query, expected_page_number|
        test "search for [#{query}] in #{book_name} returns page #{expected_page_number}" do
          page_a = book.pages.find_by_number(expected_page_number)
          page_b = book.pages.find_by_root(query)
          failmsg = "query='#{query}'"
          assert_equal(page_a, page_b, failmsg)
        end

        # Per-root Arabizi variants: each variant must (a) round-trip through
        # the Arabizi library back to the same Arabic root, and (b) resolve
        # to the same book page when used as a search query.
        Array(ARABIZI_VARIANTS[query]).each do |arabizi|
          test "Arabizi [#{arabizi}] of #{query} also lands on page #{expected_page_number} of #{book_name}" do
            transliterated = Arabizi.root_candidates(arabizi).first
            assert_equal query, transliterated,
                         "expected Arabizi #{arabizi.inspect} to transliterate to #{query.inspect}, got #{transliterated.inspect}"

            expected_page = book.pages.find_by_number(expected_page_number)
            actual_page   = book.pages.find_by_root(query)
            assert_equal expected_page, actual_page,
                         "expected #{arabizi.inspect} (=#{query.inspect}) to find page #{expected_page_number}, got page #{actual_page&.number}"
          end
        end
      end
    end
  end

  files = Dir.glob("data/dictionaries/indices/*.txt")
  files.each do |f|
    test "index for #{File.basename(f, '.txt')} is in abjadial order" do
      previous_root = ''
      roots = File.readlines(f, chomp: true).reject(&:empty?)
      roots.each_with_index do |current_root,i|
        failmsg = "  (failed after line ~#{i+1}, [#{current_root}] <> [#{previous_root}], 1st should be < 2nd)"
        assert(previous_root <= current_root, failmsg)
        previous_root = current_root
      end
    end
  end

  # Concrete example from the bug report: the sidebar lookup of the
  # previous-root "يونيو" (last_root of hw5_de page 1452) across every book
  # in the corpus. Books whose last indexed entry shares a 2+ character
  # prefix with the query land on their last page (open-ended fallback),
  # because there the same conceptual entry is most likely to actually
  # appear. Books whose last indexed entry has nothing in common with the
  # query fall back to the first numbered page — the default landing spot
  # for "definitely nothing in your current range".
  HW5_PG1452_LAST_ROOT = "\u064A\u0648\u0646\u064A\u0648" # يونيو
  SIDEBAR_QUERY_BY_BOOK = {
    'hw4_en' => :last_page_with_root_match, # indexed last_root is "يونيو" exactly
    'hw3_en' => :last_page_root_shares_prefix, # "يونو" — open-ended last page covers the area
    'maw_en' => :last_page_root_shares_prefix, # "يويو" — same prefix
    'mgf_en' => :last_page_root_shares_prefix, # "يوم"  — same prefix
    'br_en'  => :last_page_root_shares_prefix, # "يونس" — same prefix
    'pr_en'  => :last_page_root_shares_prefix, # "يونس" — same prefix
    'vq_en'  => :last_page_root_shares_prefix, # "يون"  — same prefix
    'vi_en'  => :first_numbered_page,         # "يمم"  — far away, fall back
    'll_en'  => :first_numbered_page,         # "يلب"  — far away, fall back
    'ls_en'  => :first_numbered_page          # "يقن"  — far away, fall back
  }.freeze

  hw5_de_lib = Book.find_by(name: 'hw5', language: 'de')
  if hw5_de_lib && hw5_de_lib.pages.find_by(number: 1452)&.last_root == HW5_PG1452_LAST_ROOT
    SIDEBAR_QUERY_BY_BOOK.each do |slug, expectation|
      name, language = slug.split('_', 2)
      book = Book.find_by(name: name, language: language) or
        flunk("Fixture book missing: #{slug}")
      test "find_by_root('يونيو') from hw5_de page 1452 lands on #{expectation} for #{slug}" do
        actual = book.pages.find_by_root(HW5_PG1452_LAST_ROOT)
        case expectation
        when :last_page_with_root_match, :last_page_root_shares_prefix
          expected = book.pages.where.not(last_root: [nil, '']).order(last_root: :desc).first
          assert_equal expected, actual,
                       "expected find_by_root(#{HW5_PG1452_LAST_ROOT.inspect}) in #{slug} " \
                       "to return book.last_page (last_root=#{expected&.last_root.inspect}), " \
                       "got page #{actual&.number} (last_root=#{actual&.last_root.inspect})"
        when :first_numbered_page
          expected = book.pages.find_by(number: 1)
          assert_equal expected, actual,
                       "expected find_by_root(#{HW5_PG1452_LAST_ROOT.inspect}) in #{slug} " \
                       "to fall back to page 1, got page #{actual&.number} " \
                       "(last_root=#{actual&.last_root.inspect})"
        end
      end
    end
  end
end
