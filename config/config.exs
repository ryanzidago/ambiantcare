# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ambiantcare,
  ecto_repos: [Ambiantcare.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :ambiantcare, AmbiantcareWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AmbiantcareWeb.ErrorHTML, json: AmbiantcareWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Ambiantcare.PubSub,
  live_view: [signing_salt: "gGKldpAL"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ambiantcare, Ambiantcare.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  ambiantcare: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  ambiantcare: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :nx, :default_backend, EXLA.Backend

config :mime, :types, %{
  "audio/flac" => ~w(flac)
}

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

hourly_jobs = [
  # every day, at 00:00
  {
    "0 0 * * *",
    Ambiantcare.AI.HuggingFace.AutoScalingWorker,
    args: %{"action" => "scale_to_zero"}
  },
  # every day, at 06:00
  {
    "0 6 * * *",
    Ambiantcare.AI.HuggingFace.AutoScalingWorker,
    args: %{"action" => "resume"}
  }
]

config :ambiantcare, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10],
  plugins: [
    {Oban.Plugins.Cron, crontab: hourly_jobs, timezone: "Europe/Rome"}
  ],
  repo: Ambiantcare.Repo

config :ambiantcare, Ambiantcare.Repo,
  migration_timestamps: [type: :utc_datetime],
  migration_primary_key: [name: :id, type: :binary_id],
  migration_foreign_key: [column: :id, type: :binary_id]

config :ambiantcare, :default_locale, "en"

config :ambiantcare, Ambiantcare.AI,
  backends: [
    mistral: Ambiantcare.AI.Backend.Mistral,
    huggingface: Ambiantcare.AI.HuggingFace
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
