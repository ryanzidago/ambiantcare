defmodule Ambiantcare.Utils.MapUtils do
  @spec to_string_keys(map()) :: map()
  def to_string_keys(%{} = map) do
    Map.new(map, fn
      {k, v} when is_atom(k) ->
        {Atom.to_string(k), v}

      {k, v} when is_binary(k) ->
        {k, v}
    end)
  end

  @spec to_existing_atom_keys(map()) :: map()
  def to_existing_atom_keys(%{} = map) do
    Map.new(map, fn
      {k, v} when is_binary(k) ->
        {String.to_existing_atom(k), v}

      {k, v} when is_atom(k) ->
        {k, v}
    end)
  end
end
