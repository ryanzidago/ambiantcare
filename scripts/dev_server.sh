if [ ! -f .env ]; then
  echo ".env file not found!"
  exit 1
fi

export $(cat .env) && mix format && mix ecto.migrate && iex -S mix phx.server