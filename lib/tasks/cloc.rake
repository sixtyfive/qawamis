desc 'count the lines of code and documentation of this project'
task :cloc do |t|
  `cloc config.ru Gemfile Rakefile README.md app/ config/ lib/ public/*.html public/robots.txt`
end
