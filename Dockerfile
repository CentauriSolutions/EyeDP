FROM ruby:2.6.2

ENV LANG C.UTF-8

RUN groupadd -g 1000 appuser && \
    useradd -r -u 1000 -g appuser -m appuser

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev graphviz

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs

RUN mkdir /eyedp

WORKDIR /eyedp

COPY Gemfile /eyedp/Gemfile

COPY Gemfile.lock /eyedp/Gemfile.lock
# RUN chown -R appuser:appuser /eyedp
USER appuser

RUN bundle install

COPY . /eyedp

USER root
RUN chown -R appuser:appuser /eyedp
USER appuser

CMD bundle exec puma -C config/puma.rb
