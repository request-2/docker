# how to build this reproducibly:
# For MSMS
# docker build -t request2:latest --build-arg TARGET_MSMS=1 .
# For Analytics
# docker build -t request2:latest --build-arg TARGET_MSMS=0

# docker tag request2:latest request2:`git describe --always --tags`

FROM debian:testing

ARG TARGET_MSMS

RUN apt-get -qq update && \
    apt-get install --no-install-recommends -y \
    psmisc curl procps vim \
    ghc cabal-install \
    yarnpkg \
    nginx ssmtp \
    libpq-dev postgresql-client zlib1g-dev && \
    rm -fr /var/lib/apt /var/cache/apt

# add the haskell backend
ADD cabal.project /src/request2/cabal.project
ADD request2.cabal /src/request2/request2.cabal
ADD Setup.hs /src/request2/Setup.hs
ADD CHANGELOG.md /src/request2/CHANGELOG.md
ADD README.md /src/request2/README.md
ADD LICENSE /src/request2/LICENSE
ADD selda /src/request2/selda
ADD src /src/request2/src

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

ENV REACT_APP_TARGET=${TARGET_MSMS=msms:+msms}
# if NODE_ENV is null, set it to 'production' (or leave as is otherwise).
ENV REACT_APP_TARGET=${NODE_ENV:-analytics}

# compile and install frontend
RUN cd /src/frontend && \
    yarnpkg install && \
    yarnpkg run build && \
    rm -fr node_modules && \
    cp -a /src/frontend/build /srv/frontend

RUN rm -fr /src

# add nginx config
CMD mkdir -p /srv/data
ADD docker/nginx-site /etc/nginx/sites-available/default
EXPOSE 8080

# add default config (replace this with a volume mount)
ADD docker/config /srv/config
RUN ln -sf /srv/config/ssmtp.conf /etc/ssmtp/ssmtp.conf

# add the runner and run it!
ADD docker/run.sh /srv/run.sh
CMD sg www-data -c "/bin/sh /srv/run.sh"
