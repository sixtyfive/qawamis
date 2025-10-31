# stage 1: base environment

FROM ruby:3.4 AS base
ENV APP_HOME=/app \
    BUNDLE_PATH=/usr/local/bundle
WORKDIR $APP_HOME
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  sqlite3 \
  && rm -rf /var/lib/apt/lists/*
RUN gem update --system 3.6.9 && gem install bundler -v 2.6.9
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 --retry=3

# stage 2: build

FROM base AS builder
COPY . ./
RUN rm -rf public/assets tmp/cache/*
RUN RAILS_ENV=production bundle exec rails assets:precompile

# stage 3: runtime

FROM ruby:3.4-slim
ENV APP_HOME=/app \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test"
WORKDIR $APP_HOME
RUN apt-get update -qq && apt-get install -y \
  sqlite3 \
  && rm -rf /var/lib/apt/lists/*
COPY --from=base /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app
RUN mkdir -p data/dictionaries/images
EXPOSE 3000
CMD ["bin/prod"]
