#FROM gcr.io/pace-configs/rails-base-image:1.0
FROM ruby:2.2.2
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
 
# Install RMagick
# RUN apt-get install -y libmagickwand-dev imagemagick
 
# Install Nokogiri
# RUN apt-get install -y zlib1g-dev
 
RUN echo 'alias ll="ls -l"' >> ~/.bashrc
COPY . .
RUN bundle install --path vendor/cache
RUN bundle exec rake assets:precompile

#RUN mkdir /myapp
WORKDIR /tmp
COPY Gemfile* ./
RUN bundle update json
RUN bundle install -j 4
CMD ["./infra-config/entry_point.sh"]
 
#ADD . /myapp
#WORKDIR /myapp
