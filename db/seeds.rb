# How to add a new book:
# ======================
# 
# First add a new line to the list below. There's a template line at the end. Note 
# that each page should be made available as a PNG image called
# app/assets/images/books/#{BOOK_NAME}/page_#{4-DIGIT_PAGE_NUMBER}.png.
# The EXCEPTION being the cover page, which must be page_0000.png and NOT page_0001,
# which should instead be a blank white image of the same dimensions.
#
# To put a book with two physical volumes into one virtual book, the page numbers
# need to be adjusted obviously. One such entry would be Kazimirski's dictionary:
# {name: 'kz',  language: 'fr', first_numbered_page: 11, number_of_pages: 3000}
#
# Next, each book requires an index of the last entry of each page. Page counting
# starts with "1" being the first content page (the cover page being 1-x, i.e. -19).
# The index should be made available as indices/#{BOOK}.txt, a simple text file with 
# each line containing the corresponding page's last entry. For example, if page 250 
# ends with the root كتب, line 250 of #{BOOK}.txt would read كتب. Creating these 
# files requires a UTF-8 capable text editor. Alternatively, use LibreOffice Calc
# and save as CSV with UTF-8 encoding.
#
# To go along with #{BOOK}.txt, create #{BOOK}.sh and #{BOOK}.js.tpl, using the 
# existing such files as starting points (both need to be modified accordingly!) 
# Then run #{BOOK}.sh, which should output #{BOOK}.js.
#
# Lastly, run `rake assets:precompile` if running in production mode and then run
# `rake db:seed` to fill the database with the content put into the .js files by
# the .sh scripts. I know all of this is somewhat cumbersome but it allows using
# Abdurahman Erik Taal's indices so there's some benefit to doing it this way.
#
# TL;DR:
# ======
# 
# 1. Add book to list above
# 2. Put pages into app/assets/images/books/mybook/page_1234.png
# 3. Rename page_0001.png to page_0000.png
# 4. Make a new blank white page named page_0001.png
# 5. In indices/, create mybook.txt, mybook.sh, mybook.js.tpl
# 6. In indices/, run mybook.sh
# 7. Run `rake assets:precompile` and `rake db:seed`
# 8. ??? :-)
#
# Note:
# -----
#
# None of the Urdu books present in Abdurahman Erik Taal's Arabic Almanac are part
# of this project at present, as I don't have any use for them. Again, always open
# to pull requests though :-).

                                # Count from cover,      # Mawrid URL parameter,
books = [                       # starting with "1"      # add "1", but check!
  {name: 'hw5', language: 'de', first_numbered_page: 26, number_of_pages: 1478},
  {name: 'hw4', language: 'en', first_numbered_page: 14, number_of_pages: 1316},
  {name: 'll',  language: 'en', first_numbered_page: 39, number_of_pages: 3079},
  {name: 'ls',  language: 'en', first_numbered_page:  3, number_of_pages:   85},
  {name: 'doe', language: 'en', first_numbered_page: 20, number_of_pages:  998},
  {name: 'sg',  language: 'en', first_numbered_page: 20, number_of_pages: 1263},
  {name: 'ha',  language: 'en', first_numbered_page: 21, number_of_pages:  919},
  {name: 'la',  language: 'ar', first_numbered_page:  1, number_of_pages: 4979},
  {name: 'maw', language: 'en', first_numbered_page: 16, number_of_pages: 1256},
  {name: 'amj', language: 'ar', first_numbered_page: 22, number_of_pages: 1036},
  {name: 'hw3', language: 'en', first_numbered_page: 19, number_of_pages: 1130},
  {name: 'br',  language: 'en', first_numbered_page: 26, number_of_pages: 1092},
  {name: 'pr',  language: 'en', first_numbered_page:  9, number_of_pages:  177},
  {name: 'vq',  language: 'en', first_numbered_page: 24, number_of_pages:  757},
  {name: 'mgf', language: 'en', first_numbered_page: 35, number_of_pages:  880},
  {name: 'vi',  language: 'en', first_numbered_page: 51, number_of_pages:  400}
  #
  # {name: '', language: '', first_numbered_page: , number_of_pages: } # Template for new book.
  # ``language'' is the book's secondary language, i.e., the one that is not Arabic.
]

require 'v8'
js = String.new

books.each do |book|
  file = File.join(Rails.root, 'indices', "#{book[:name]}.js")
  js  += IO.read(file)
end

cxt = V8::Context.new
cxt.eval(js)
roots = Hash.new

books.each do |book|
  _book = Book.create(name: book[:name], language: book[:language], first_numbered_page: book[:first_numbered_page])
  roots[_book.name.to_sym] = cxt[_book.name.to_sym]
  ActiveRecord::Base.transaction do
    (1..book[:number_of_pages]).each do |page|
      name = book[:name]
      root = roots[_book.name.to_sym][page-1]
      root = root.gsub(',', '') if root
      puts "#{name}: [##{page}] (#{page-_book.first_numbered_page} - #{root})"
      _book.pages << Page.create(
        number: page - _book.first_numbered_page,
        last_root: roots[_book.name.to_sym][page-1]
      )
    end
  end
end
