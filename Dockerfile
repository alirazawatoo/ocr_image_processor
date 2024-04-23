# syntax = docker/dockerfile:1

# Keep RUBY_VERSION in step with .ruby-version
ARG RUBY_VERSION=3.4.12
FROM ruby:$RUBY_VERSION-slim-bookworm AS base

WORKDIR /rails

# Runtime libraries: Postgres client, ImageMagick for RMagick, Tesseract with English data
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libpq5 libmagickwand-6.q16-6 \
      tesseract-ocr tesseract-ocr-eng && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"


FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev \
      libmagickwand-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

# Assets compile without real secrets
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


FROM base

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run as an unprivileged user that owns only the writable runtime folders
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p db log storage tmp && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
