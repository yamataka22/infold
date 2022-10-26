FROM ruby:3.1.2
ENV LANG C.UTF-8

RUN apt-get update -qq && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

# add user
RUN useradd -m -u 1000 infold
RUN mkdir /infold && chown infold /infold
USER infold

WORKDIR /infold
EXPOSE 3000
RUN gem install bundler
ENV THOR_SILENCE_DEPRECATION="1"
