FROM ruby:3.1.2
ENV LANG C.UTF-8

RUN apt-get update -qq && \
    apt-get install -y \
      nodejs \
      npm \
      --no-install-recommends && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

# node, npm
RUN npm install n -g && \
    n 17.5.0 && \
    apt-get purge -y nodejs npm

# yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt update && \
    apt install -y yarn --no-install-recommends

# add user
RUN useradd -m -u 1000 infold
RUN mkdir /infold && chown infold /infold
USER infold

WORKDIR /infold
EXPOSE 3000
RUN gem install bundler
ENV THOR_SILENCE_DEPRECATION="1"
