defmodule Cloak.Ecto.MapList do
  defmacro __using__(opts) do
    opts = Keyword.merge(opts, vault: Keyword.fetch!(opts, :vault))

    quote location: :keep do
      use Cloak.Ecto.Type, unquote(opts)

      alias Cloak.Config

      def cast(closure) when is_function(closure, 0) do
        cast(closure.())
      end

      def cast(value) do
        Ecto.Type.cast({:array, :map}, value)
      end

      def before_encrypt(value) do
        unquote(opts[:vault]).json_library().encode!(value)
      end

      def after_decrypt(value) do
        unquote(opts[:vault]).json_library().decode!(value)
      end
    end
  end
end
