defmodule Clipboard.Utils.Map do
  def to_string_keys(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) ->
        {Atom.to_string(k), v}

      {k, v} when is_binary(k) ->
        {k, v}
    end)
  end
end
