# stage 1: base environment

FROM ruby:3.3 AS base
ENV APP_HOME=/app \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test"
WORKDIR $APP_HOME
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  nodejs \
  sqlite3 \
  && rm -rf /var/lib/apt/lists/*
RUN gem update --system 3.6.3 && gem install bundler -v 2.6.3
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 --retry=3

# stage 2: build

FROM base AS builder
COPY . ./
RUN rm -rf public/assets tmp/cache
RUN rm -f public/images/books # left-over symlink from development
RUN RAILS_ENV=production bundle exec rake assets:precompile

# stage 3: runtime

FROM ruby:3.3-slim
ENV APP_HOME=/app \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test"
WORKDIR $APP_HOME
RUN apt-get update -qq && apt-get install -y \
  nodejs \
  sqlite3 \
  && rm -rf /var/lib/apt/lists/*
COPY --from=base /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app
RUN rm -rf app/assets/{images,javascripts,stylesheets}
RUN mkdir -p /app/public/images/books
EXPOSE 3000
CMD ["bundle", "exec", "rake", "serve"]
