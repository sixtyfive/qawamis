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

  test "all article lists are in alphabetical order" do
    files = Dir.glob("indices/*.txt")
    files.each do |f|
      puts "\nTesting #{f}:"
      file = File.open(f, 'r')
      lastline = '0'
      i = 0
      while (line = file.gets)
        puts "line [#{line.chomp}] >= lastline [#{lastline.chomp}]: #{(line >= lastline).to_s}"
        if assert_equal(true, (line >= lastline), "Failed at #{f}##{i}/#{i+1}: [-#{line.gsub(/(.)/, ' \1 -').strip}] < [-#{lastline.gsub(/(.)/, ' \1 -').strip}]")
          lastline = line
        end
        i += 1
      end
      file.close
    end
  end

  test "all previously failed searches now return the correct page" do
    REPORTED_FAILED.each do |b, tests|
      if book = Book.find_by_name(b)
        puts "\nTesting #{b}:"
        tests.each do |search_string, expected_page_number|
          page_a = book.pages.find_by_number(expected_page_number)
          page_b = book.pages.find_by_root(search_string)
          puts "page [#{page_a.number}] == page [#{page_b.number}]: #{(page_a == page_b).to_s}"
          assert_equal(page_a, page_b, "search_string='#{search_string}'")
        end
      end
    end
  end
end
