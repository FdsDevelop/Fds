FROM ruby:3.3

ENV BUNDLE_APP_CONFIG=.bundle

RUN apt-get update && apt-get install -y --no-install-recommends \
  nodejs \
  npm \
  postgresql-client \
  vim

RUN gem install rails

WORKDIR /app
