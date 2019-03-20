#FROM gcr.io/pace-configs/rails-base-image:1.0
FROM ruby:2.2.2
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
 
# Install RMagick
# RUN apt-get install -y libmagickwand-dev imagemagick
 
# Install Nokogiri
# RUN apt-get install -y zlib1g-dev

RUN mkdir /myapp
WORKDIR /myapp
ADD Gemfile /myapp/
ADD Gemfile.lock /myapp/
COPY Gemfile Gemfile
RUN bundle update json
RUN bundle install -j 4
 
ADD . /myapp
