source 'https://rubygems.org'

gem 'rake', '13.2.1'

gem 'railties', '~> 8.1.0'
gem 'activerecord', '~> 8.1.0'
gem 'actionpack', '~> 8.1.0'
gem 'actionview', '~> 8.1.0'
gem 'activemodel', '~> 8.1.0'
gem 'activesupport', '~> 8.1.0'

gem 'puma'
gem 'sqlite3'
gem 'dalli'
gem 'http_accept_language'
gem 'lograge'
gem 'haml-rails'

gem 'importmap-rails' # for JS only
gem 'dartsass-rails' # replaces sassc
gem 'propshaft' # basically the new Sprockets

gem 'benchmark'
gem 'i18n-js'

group :development do
  gem 'execjs'
end

group :test do
  # TODO:
  # collator = TwitterCldr::Collation::Collator.new(:de)
  # collator.compare("Art", "Älg")           # 1
  # collator.compare("Älg", "Art")           # -1
  # collator.compare("Art", "Art")           # 0
  gem 'twitter_cldr'
end
