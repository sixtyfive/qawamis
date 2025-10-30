task :cloc do |t|
  `cloc config.ru Gemfile Rakefile README.md app/ config lib public/*.html public/robots.txt`
end
