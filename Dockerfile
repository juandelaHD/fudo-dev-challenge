FROM ruby:3.4.7-alpine

WORKDIR /app

RUN apk add --no-cache build-base libpq-dev

COPY Gemfile.rb Gemfile

RUN bundle install

COPY . .

EXPOSE 9292

CMD ["rackup", "--host", "0.0.0.0", "--port", "9292"]
