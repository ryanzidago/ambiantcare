asdf install \
  && cd assets \
  && yarn install \
  && cd .. \
  && mix local.hex --force \
  && mix deps.get \
  && ./scripts/dev_server.sh