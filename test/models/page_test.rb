require 'test_helper'
 
class PageTest < ActiveSupport::TestCase
  ROOT_PAGE_PAIRS = [
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

  test "all root searches return the correct page" do
    ROOT_PAGE_PAIRS.each do |search_string, expected_page_number|
      assert_equal(
        Book.first.pages.find_by_number(expected_page_number),
        Book.first.pages.find_by_root(search_string),
        "search_string='#{search_string}'")
    end
  end
end
