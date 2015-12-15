# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

require 'v8'
js = String.new
roots = Hash.new
%w{mr-aa-hw5-index.js mr-aa-indexes.js mr-aa-hw3-index.js mr-mr-indexes.js mr-aa-amj-index.js}.each do |file|
  js += IO.read(File.join(Rails.root, 'indices', file))
end
cxt = V8::Context.new
cxt.eval(js)

                                # Count from cover,      # Mawrid URL parameter,
books = [                       # starting with "1"      # add "1", but check!
  {name: 'hw5', language: 'de', first_numbered_page: 26, number_of_pages: 1478},
  {name: 'hw4', language: 'en', first_numbered_page: 14, number_of_pages: 1316},
  {name: 'll',  language: 'en', first_numbered_page: 39, number_of_pages: 3079},
  {name: 'ls',  language: 'en', first_numbered_page:  3, number_of_pages:   85},
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
  # After adding the book here, move the cover page
  # image to page_0000.png and move a blank page to
  # page_0001.png instead.
  #
  # Template:
  # {name: '', language: '', first_numbered_page: , number_of_pages: }
  #
  # 2 Volumes in 1, needs to be split...
  # {name: 'kz',  language: 'fr', first_numbered_page: 11, number_of_pages: 3000}
  #
  # Leaving out all the Urdu books for now since I've no use for them and there's
  # other things still to be done. If anyone misses them, I'm always open to pull
  # requests! :-)
].each do |book|
  _book = Book.create(name: book[:name], language: book[:language], first_numbered_page: book[:first_numbered_page])
  # _book = Book.new(name: book[:name], language: book[:language], first_numbered_page: book[:first_numbered_page])
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
