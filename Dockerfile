FROM ruby:2.2.2
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
 
# Install RMagick
# RUN apt-get install -y libmagickwand-dev imagemagick
 
# Install Nokogiri
# RUN apt-get install -y zlib1g-dev
 
RUN mkdir /myapp
WORKDIR /tmp
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle update json
RUN bundle install -j 4
RUN bundle exec jekyll build
 
ADD . /myapp
WORKDIR /myapp
