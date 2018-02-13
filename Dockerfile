FROM m1yag1/ruby-ubuntu:2.2.3

LABEL author="OpenStax"

RUN apt-get install -y postgresql-client-9.5

# Set important environmental variabls
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_BIN="$GEM_HOME/bin" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
ENV INSTALL_PATH /app

RUN mkdir -p $INSTALL_PATH

# Sets the context of where commands will be run
WORKDIR $INSTALL_PATH

# Cache ruby gems
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

# Copy over the application code
COPY . ./
