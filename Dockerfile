ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION-slim-buster
ARG PG_MAJOR
ARG NODE_MAJOR
ARG BUNDLER_VERSION

# Common dependencies
RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    less \
    git \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# Add PostgreSQL and nodejs to sources list
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list && \
  curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Application dependencies
COPY .ops/Aptfile /tmp/Aptfile

RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    libpq-dev \
    postgresql-client-$PG_MAJOR \
    $(cat /tmp/Aptfile | xargs) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Configure locale, bundler, define app dir
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3 \
  APP_USER=app \
  HOME_APP=/home/app/web

# Create a user and directory for the app code
RUN useradd --user-group --create-home --no-log-init --shell /bin/bash $APP_USER && \
    mkdir -p $HOME_APP \
    chown $APP_USER:$APP_USER /home/app && \
    chown $APP_USER:$APP_USER $HOME_APP

USER $APP_USER

WORKDIR $HOME_APP

COPY --chown=$APP_USER .ops/.gitconfig /home/app/.gitconfig

COPY --chown=$APP_USER . ./

# Upgrade RubyGems, add github to known_hosts, add .gitconfig, install required Bundler version
RUN gem update --system && \
    gem install bundler:$BUNDLER_VERSION && \
     mkdir -p ~/.ssh && \
    umask 0077 && \
    touch ~/.ssh/known_hosts && \
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts && \
    bundle check || bundle install && \
    rm ~/.gitconfig
