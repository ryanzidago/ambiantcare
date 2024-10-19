if [ ! -f .env ]; then
  echo ".env file not found!"
  exit 1
fi

export $(cat .env) && mix format && iex -S mix phx.server