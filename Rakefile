# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task :cloc do |t|
  `cloc config.ru Gemfile Rakefile README.md app/ config lib public/*.html public/robots.txt`
end
