FROM gcr.io/pace-configs/rails-base-image:1.0

ENV APP_HOME /home/logistics
WORKDIR $APP_HOME

COPY Gemfile* ./
RUN bundle install --jobs 20 --retry 5

RUN echo 'alias ll="ls -l"' >> ~/.bashrc

COPY . .
RUN bundle exec rake assets:precompile

# Unicorn
EXPOSE 5000
# Built-in prometheus exporter
#Commnent Added for JENKINS Setup
EXPOSE 9394

CMD ["./infra-config/entry_point.sh"]
