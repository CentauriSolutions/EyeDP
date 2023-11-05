FROM ruby:3.1

ENV LANG C.UTF-8
ENV RAILS_ENV=production

RUN groupadd -g 1000 appuser && \
    useradd -r -u 1000 -g appuser -m appuser

RUN apt-get update -qq && apt-get install -y git build-essential libpq-dev graphviz

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs

RUN mkdir /eyedp

WORKDIR /eyedp

COPY Gemfile /eyedp/Gemfile

COPY Gemfile.lock /eyedp/Gemfile.lock
# RUN chown -R appuser:appuser /eyedp
USER appuser

RUN bundle install --without development test

COPY . /eyedp

USER root
RUN chown -R appuser:appuser /eyedp
USER appuser
RUN npm install
RUN SECRET_KEY_BASE=`bin/rake secret` bundle exec rake assets:precompile
CMD bundle exec puma -C config/puma.rb
