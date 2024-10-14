FROM ruby:3.0-alpine
RUN apk add --no-cache build-base bash
RUN adduser -D myuser
USER myuser
WORKDIR /app
COPY Gemfile Gemfile.lock /app/
RUN bundle install
COPY . /app/
CMD ["rails", "server", "-b", "0.0.0.0"]
