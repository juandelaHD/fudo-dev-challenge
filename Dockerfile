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

CMD bundle exec rackup --host ${HOST:-0.0.0.0} --port ${PORT:-9292}
