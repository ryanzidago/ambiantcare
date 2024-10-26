defmodule Ambiantcare.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ai_config = Application.get_env(:ambiantcare, Ambiantcare.AI, [])
    use_local_stt? = Keyword.get(ai_config, :use_local_stt, false)

    children =
      [
        AmbiantcareWeb.Telemetry,
        Ambiantcare.Repo,
        Ambiantcare.Vault,
        {DNSCluster, query: Application.get_env(:ambiantcare, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Ambiantcare.PubSub},
        # Start the Finch HTTP client for sending emails
        {Finch, name: Ambiantcare.Finch},
        {Oban, Application.fetch_env!(:ambiantcare, Oban)},
        # Start to serve requests, typically the last entry
        AmbiantcareWeb.Endpoint
      ] ++ maybe_nx_serving(use_local_stt?)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ambiantcare.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AmbiantcareWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp maybe_nx_serving(_use_local_stt? = true) do
    {:ok, model_info} = Bumblebee.load_model({:hf, "openai/whisper-base"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "openai/whisper-base"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "openai/whisper-base"})

    {:ok, generation_config} =
      Bumblebee.load_generation_config({:hf, "openai/whisper-base"})

    serving =
      Bumblebee.Audio.speech_to_text_whisper(model_info, featurizer, tokenizer, generation_config,
        compile: [batch_size: 4],
        defn_options: [compiler: EXLA]
      )

    [{Nx.Serving, serving: serving, name: Ambiantcare.Serving, batch_timeout: 100}]
  end

  defp maybe_nx_serving(_), do: []
end
