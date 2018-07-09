from ruby:2.3.6

copy Gemfile* /bundle/

workdir /bundle

run bundle install
