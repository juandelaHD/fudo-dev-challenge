FROM ruby:3.4.7-alpine

WORKDIR /app

# Instalar dependencias del sistema
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    tzdata

COPY Gemfile ./

RUN bundle install

COPY . .

EXPOSE 9292

ENV RUBY_IOENCODING=UTF-8

CMD bundle exec puma --quiet -b tcp://${HOST:-0.0.0.0}:${PORT:-9292} -e ${RACK_ENV:-development} config.ru
