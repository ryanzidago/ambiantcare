defmodule Ambiantcare.Vault do
  use Cloak.Vault, otp_app: :ambiantcare

  @impl GenServer
  def init(config) do
    ciphers = [
      default: {
        Cloak.Ciphers.AES.GCM,
        tag: "AES.GCM.V1", key: decode_env!("CLOAK_ENCRYPTION_KEY"), iv_length: 12
      }
    ]

    config =
      config
      |> Keyword.put(:ciphers, ciphers)
      |> Keyword.put(:json_library, Jason)

    {:ok, config}
  end

  defp decode_env!(var) do
    var
    |> System.fetch_env!()
    |> Base.decode64!()
  end
end
