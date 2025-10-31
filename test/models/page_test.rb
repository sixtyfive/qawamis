require 'test_helper'
 
class PageTest < ActiveSupport::TestCase
  REPORTED_FAILED = {
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

  REPORTED_FAILED.each do |book_name, tests|
    if book = Book.find_by_name(book_name)
      tests.each do |query, expected_page_number|
        test "search for [#{query}] in #{book_name} returns page #{expected_page_number}" do
          page_a = book.pages.find_by_number(expected_page_number)
          page_b = book.pages.find_by_root(query)
          failmsg = "query='#{query}'"
          assert_equal(page_a, page_b, failmsg)
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
end
