task :serve do |t|
  loop do
    `bundle exec rails s -e production -p 3000 -b 0.0.0.0`
  end
end
