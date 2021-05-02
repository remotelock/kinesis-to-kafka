FROM ruby:3.0

RUN mkdir /app
WORKDIR /app

# Dependencies
RUN apt-get update
# For gem nokogiri
RUN apt-get install -y libxml2-dev libxslt1-dev
# For gem aws-kclrb
RUN apt-get install -y default-jre-headless

# Install gems before copying the app code to benefit from docker layer caching
COPY Gemfile* /app/
RUN gem install bundler -v '~> 2'
RUN bundle config set --local without 'development:test'
RUN bundle install --jobs=4

COPY . /app

CMD bash -c "source bin/set_java_home; bundle exec rake kinesis_to_kafka:run"
