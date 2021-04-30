ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION

# Setup the Google Chrome repository
RUN wget --quiet --output-document=- https://dl-ssl.google.com/linux/linux_signing_key.pub | \
    APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -
RUN echo 'deb https://dl.google.com/linux/chrome/deb/ stable main' \
         > /etc/apt/sources.list.d/google-chrome.list

ARG NODE_JS_MAJOR_VERSION

# The nodejs setup script already calls apt-get update,
# but just in case they stop doing it we call it here again
RUN wget --quiet --output-document=- https://deb.nodesource.com/setup_$NODE_JS_MAJOR_VERSION.x | \
    bash - && \
    apt-get update && \
    apt-get install --yes libjemalloc2 nodejs google-chrome-stable && \
    rm --recursive --force /var/lib/apt/lists/*

# Make ruby use libjemalloc
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# Install yarn as a global npm package
RUN npm install --global yarn

# Add a user to the container that will own the application code
RUN adduser --system --group --home /tutor tutor
USER tutor

# The separate mkdir step is necessary to properly set permissions for /tutor/src
RUN mkdir /tutor/src
WORKDIR /tutor/src

# Copy only the Gemfiles and run bundle install,
# so the cache is valid until the Gemfile or Gemfile.lock change
COPY --chown=tutor Gemfile* ./
RUN gem install bundler --force --no-document && \
    bundle config deployment true && \
    bundle config path /tutor/bundle && \
    bundle config jobs $(nproc) && \
    bundle install

# Copy the rest of the application
COPY --chown=tutor . .

# Use docker/entrypoint.rb as the entrypoint
# It'll setup the database, run migrations and create the demo data
# The default command is bin/rails server, which starts up the puma server on localhost port 3001
ENTRYPOINT ["docker/entrypoint.rb"]
CMD ["bin/rails", "server", "--binding=0.0.0.0"]
