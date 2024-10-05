asdf install \
  && cd assets \
  && yarn install \
  && cd .. \
  && mix local.hex --force \
  && mix deps.get \
  && mix ecto.setup \
  && ./scripts/dev_server.sh