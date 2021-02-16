FROM debian:testing

RUN apt-get -qq update && \
    apt-get --no-install-recommends -y psmisc curl procps vim \
    	ghc cabal-install \
	yarnpkg \
	nginx ssmtp \
	libpq-dev postgresql-client

# add haskell project
ADD cabal.project /src/request2/cabal.project
ADD request2.cabal /src/request2/request2.cabal
ADD Setup.hs /src/request2/Setup.hs
ADD selda /src/request2/selda
ADD src /src/request2/src

# compile and install backend
RUN cabal update
RUN cd /src/request2 && cabal install

# add frontend
ADD frontend /src/frontend

# compile and install frontend
RUN cd /src/frontend && yarnpkg install && yarnpkg run build
RUN cp -a /src/frontend/build /srv/frontend

# add nginx config
ADD docker/nginx-site /etc/nginx/sites-available/default
RUN mkdir /srv
EXPOSE 8080

# add default config (replace this with a volume mount)
ADD docker/config /srv/config
RUN ln -sf /srv/config/ssmtp.conf /etc/ssmtp/ssmtp.conf

# add the runner and run it!
ADD docker/run.sh /srv/run.sh
CMD /srv/run.sh
