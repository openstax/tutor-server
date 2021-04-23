FROM ruby:2.7.2

RUN adduser --system --group --home /tutor tutor
USER tutor

RUN mkdir /tutor/src

COPY --chown=tutor Gemfile* /tutor/src/
WORKDIR /tutor/src
RUN bundle config deployment true && \
    bundle config path /tutor/bundle && \
    BUNDLE_JOBS=2 bundle install

COPY --chown=tutor . .

RUN bin/rake db:setup demo[mini] jobs:workoff assets:precompile

ENTRYPOINT ["/tutor/src/docker/entrypoint"]
CMD docker/start
