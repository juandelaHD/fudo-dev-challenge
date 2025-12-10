FROM ruby:3.4.7-alpine

WORKDIR /app

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    tzdata

COPY Gemfile ./

RUN bundle install

COPY . .

RUN chmod +x docker-entrypoint.sh

EXPOSE 9292

ENV RUBY_IOENCODING=UTF-8

ENTRYPOINT ["./docker-entrypoint.sh"]

CMD ["sh", "-c", "bundle exec rackup --host ${HOST:-0.0.0.0} --port ${PORT:-9292} --env ${RACK_ENV:-development} config.ru"]
