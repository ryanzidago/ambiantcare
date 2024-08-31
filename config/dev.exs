import Config

# Configure your database
config :clipboard, Clipboard.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "clipboard_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :clipboard, ClipboardWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "Ke60J4Sq5Dxr8Z6gRAL7CVQwG/86zLHiXcHZsMy03RA4xB1aKgTKMj7l4ji/w1Sr",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:clipboard, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:clipboard, ~w(--watch)]}
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :clipboard, ClipboardWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/clipboard_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :clipboard, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Include HEEx debug annotations as HTML comments in rendered markup
  debug_heex_annotations: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

config :clipboard, Clipboard.AI.HuggingFace,
  api_key: System.get_env("HUGGING_FACE_API_KEY"),
  deployment: System.get_env("HUGGING_FACE_DEPLOYMENT") || "dedicated",
  serverless: [
    api_endpoint: "https://api-inference.huggingface.co/models"
  ],
  dedicated: [
    namespace: "GetClipboard",
    api_endpoint: "https://api.endpoints.huggingface.cloud/v2",
    model_endpoints: [
      open_ai_whisper_large_v3:
        System.get_env("HUGGING_FACE_DEDICATED_OPEN_AI_WHISPER_LARGE_V3_ENDPOINT"),
      meta_llama_3_1_8b_instruct:
        System.get_env("HUGGING_FACE_DEDICATED_META_LLAMA_3_1_8B_INSTRUCT_ENDPOINT")
    ]
  ]

config :clipboard, Clipboard.AI.Mistral,
  base_url: "https://api.mistral.ai",
  api_key: System.get_env("MISTRAL_API_KEY"),
  agents: [
    medical_note_agent_id: System.get_env("MISTRAL_MEDICAL_NOTE_AGENT_ID")
  ]

config :clipboard, Clipboard.AI.Ollama, base_url: "http://localhost:11434"

config :clipboard, Clipboard.AI.Ollama, base_url: "http://localhost:11434"
