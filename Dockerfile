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

RUN chmod +x docker-entrypoint.sh

EXPOSE 9292

ENV RUBY_IOENCODING=UTF-8

ENTRYPOINT ["./docker-entrypoint.sh"]

CMD ["bundle", "exec", "puma", "--quiet", "-b", "tcp://0.0.0.0:9292", "-e", "development", "config.ru"]
