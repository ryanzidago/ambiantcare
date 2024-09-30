defmodule Ambiantcare.Repo do
  use Ecto.Repo,
    otp_app: :ambiantcare,
    adapter: Ecto.Adapters.Postgres
end
