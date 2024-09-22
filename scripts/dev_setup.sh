asdf install \
  && cd assets \
  && yarn install \
  && cd .. \
  && mix deps.get \
  && ./scripts/dev_server.sh