# stage 1: build

FROM ruby:2.6 AS builder
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  nodejs \
  sqlite3 \
  && rm -rf /var/lib/apt/lists/*
ENV BUNDLE_PATH="/usr/local/bundle"
ENV BUNDLE_WITHOUT="development:test"
RUN mkdir -p /app && rm -rf /app/.bundle
RUN gem update --system 3.3.22 && \
    gem install bundler -v 2.4.22 && \
    bundle install
COPY . ./
RUN rm -rf .bundle
RUN mkdir -p log tmp db config
RUN bundle exec rake assets:precompile RAILS_ENV=production

# stage 2: runtime only environment

FROM ruby:2.6-slim
WORKDIR /app
RUN apt-get update -qq && apt-get install -y \
  nodejs \
  sqlite3 \
  && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
ENV BUNDLE_PATH="/usr/local/bundle"
ENV BUNDLE_WITHOUT="development:test"
RUN rm -rf /app/.bundle
RUN mkdir -p log tmp db config
EXPOSE 3000

# Default startup command
CMD ["bundle", "exec", "rake", "serve"]
