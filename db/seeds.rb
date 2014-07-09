# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

require 'v8'
js = String.new
roots = Hash.new
%w{mr-aa-hw3-index.js mr-aa-hw5-index.js mr-aa-indexes.js mr-mr-indexes.js}.each do |file|
  js += IO.read(File.join(Rails.root, 'mawrid', file))
end
cxt = V8::Context.new
cxt.eval(js)

books = [
  {name: 'hw5', language: 'de', first_numbered_page: 26, number_of_pages: 1478},
  {name: 'hw4', language: 'en', first_numbered_page: 14, number_of_pages: 1316},
  {name: 'hw3', language: 'en', first_numbered_page: 19, number_of_pages: 1130},
  {# name: 'kz',  language: 'fr', first_numbered_page: 11, number_of_pages: 3000} 2 Bände?!
  {name: 'maw', language: 'en', first_numbered_page: 16, number_of_pages: 1256}
].each do |book|
  _book = Book.create(name: book[:name], language: book[:language], first_numbered_page: book[:first_numbered_page])
  roots[_book.name.to_sym] = cxt[_book.name.to_sym]
  ActiveRecord::Base.transaction do
    (1..book[:number_of_pages]).each do |page|
      _book.pages << Page.create(
        number: page - _book.first_numbered_page,
        last_root: roots[_book.name.to_sym][page-1]
      )
    end
  end

end
