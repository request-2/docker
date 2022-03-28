# how to build this reproducibly (from the "environment" package):
# rqtag=-yourlab
# docker build -f docker/Dockerfile --squash=true -t request2${rqtag}:latest .
# docker tag request2${rqtag}:latest request2${rqtag}:`git describe --always --tags`

FROM debian:testing

RUN apt-get -qq update && \
    apt-get install --no-install-recommends -y \
    psmisc curl procps vim \
    ghc cabal-install \
    yarnpkg \
    nginx ssmtp \
    libpq-dev postgresql-client zlib1g-dev

# add the haskell backend
ADD backend /src/request2

# create a directory for serving stuff
RUN mkdir -p /srv

# compile and install backend
RUN cabal update && \
    cd /src/request2 && \
    cabal install && \
    cp -L /root/.cabal/bin/request2 /usr/bin/request2 && \
    rm -fr /root/.cabal

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

# clean everything
RUN rm -fr /src
RUN apt-get -y remove yarnpkg ghc cabal-install && \
    apt-get -y autoremove && \
    rm -fr /var/lib/apt /var/cache/apt && \
    rm -fr /usr/local/share/.cache # omg yarn!

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
