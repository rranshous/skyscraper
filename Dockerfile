FROM ruby:2.2.0

RUN mkdir /data
ADD ./ /app
WORKDIR /app
RUN bundle install

EXPOSE 80
VOLUME /data
ENV DATA_DIR=/data

ENTRYPOINT ["bundle", "exec", "ruby", "app.rb", "-p", "80", "-o", "0.0.0.0"]
