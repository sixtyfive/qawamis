FROM ruby:3.4 AS base
ENV APP_HOME=/app \
  BUNDLE_PATH=/usr/local/bundle
WORKDIR $APP_HOME

RUN apt-get update -qq && apt-get install -y \
  build-essential sqlite3 && rm -rf /var/lib/apt/lists/*

RUN gem update --system 3.6.9 && gem install bundler -v 2.6.9

COPY Gemfile Gemfile.lock ./
RUN bundle install

FROM base AS dev

ENV RAILS_ENV=development

WORKDIR /app
CMD ["bin/rails", "server", "-b", "0.0.0.0"]

FROM base AS prod

ENV RAILS_ENV=production \
  BUNDLE_WITHOUT="development:test"

COPY . .
RUN bundle exec rails assets:precompile

CMD ["bin/prod"]