FROM ruby:2.3.6

RUN apt-get update && apt-get install -y \
    curl \
    netcat \
  && rm -rf /var/lib/apt/lists/*

RUN curl https://raw.githubusercontent.com/eficode/wait-for/master/wait-for -o /usr/local/bin/wait-for \
  && chmod a+x /usr/local/bin/wait-for

RUN addgroup --system tutor \
  && adduser --system --group --home /code tutor

RUN mkdir /bundle && chown tutor:tutor /bundle

USER tutor

RUN mkdir /code/tmp && chown tutor:tutor /code/tmp \
  && mkdir /code/log && chown tutor:tutor /code/log

ENV BUNDLE_PATH=/bundle

WORKDIR /code

COPY --chown=tutor . .

RUN bundle install

ENTRYPOINT ["/code/docker/entrypoint"]

CMD docker/start
