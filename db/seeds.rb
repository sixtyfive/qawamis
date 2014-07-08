# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Hans Wehr, 5. Auflage, deutsch

book = Book.create(name: 'hw5', language: 'de', first_numbered_page: 26)

ActiveRecord::Base.transaction do
  (1..1478).each do |page|
    book.pages << Page.create(number: page-book.first_numbered_page, last_root: 'ا')
  end
end

book = Book.create(name: 'hw4', language: 'en', first_numbered_page: 11)

ActiveRecord::Base.transaction do
  (1..1316).each do |page|
    book.pages << Page.create(number: page-book.first_numbered_page, last_root: 'ا')
  end
end
