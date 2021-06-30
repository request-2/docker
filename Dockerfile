# how to build this reproducibly:
# docker build -t request2:latest
# docker tag request2:latest request2:`git describe --always --tags`

FROM debian:testing

RUN apt-get -qq update && \
    apt-get install --no-install-recommends -y \
    psmisc curl procps vim \
    ghc cabal-install \
    yarnpkg \
    nginx ssmtp \
    libpq-dev postgresql-client zlib1g-dev && \
    rm -fr /var/lib/apt /var/cache/apt

# add the haskell backend
ADD backend /src/request2

# create a directory for serving stuff
RUN mkdir -p /srv

# compile and install backend
RUN cabal update && \
    cd /src/request2 && \
    cabal install && \
    rm -fr /root/.cabal/packages

# add frontend
ADD frontend /src/frontend
ADD docker/react-env /src/frontend/.env

# compile and install frontend
ADD RequestTypes /src/RequestTypes
RUN cd /src/frontend && \
    yarnpkg install && \
    yarnpkg run loadforms && \
    yarnpkg run build && \
    rm -fr node_modules && \
    cp -a /src/frontend/build /srv/frontend

RUN rm -fr /src

# add nginx config
CMD mkdir -p /srv/data
ADD docker/nginx-site /etc/nginx/sites-available/default
EXPOSE 8080

# add default config (replace this with a volume mount)
ADD config /srv/config
RUN ln -sf /srv/config/ssmtp.conf /etc/ssmtp/ssmtp.conf

# add the runner and run it!
ADD docker/run.sh /srv/run.sh
CMD sg www-data -c "/bin/sh /srv/run.sh"
