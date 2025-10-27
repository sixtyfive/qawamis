# stage 1: build

FROM ruby:2.6 AS builder
WORKDIR /app

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  nodejs \
  sqlite3 \
  && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN gem update --system 3.3.22 && \
    gem install bundler -v 1.17.3 && \
    bundle install --without development test --path vendor/bundle
COPY . ./
RUN mkdir -p log tmp
RUN bundle exec rake assets:precompile RAILS_ENV=production

# stage 2: runtime only environment

FROM ruby:2.6-slim
WORKDIR /app

RUN apt-get update -qq && apt-get install -y \
  nodejs \
  sqlite3 \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app /app
RUN mkdir -p log tmp
EXPOSE 3000

# Default startup command
CMD ["bundle", "exec", "rake", "serve"]
