# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task :cloc do |t|
  `cloc config.ru Gemfile Rakefile README.md app/ config lib public/*.html public/robots.txt`
end

task :serve do |t|
  loop do
    `bundle exec rails s -e production -p 3000 -b 0.0.0.0`
  end
end

namespace :docker do
  desc "Clean and rebuild the Docker environment completely"
  task :rebuild do
    `docker compose down --rmi all --volumes --remove-orphans`
    `docker compose build --no-cache --pull --platform linux/amd64 -t qawamis:latest .`
    `docker compose up -d`
    `docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'`
  end
end
