defmodule Ambiantcare.Waitlists do
  alias Ambiantcare.Repo
  alias Ambiantcare.Waitlists.UserEntry

  import Ecto.Query

  @spec insert_user_entry(map()) :: {:ok, UserEntry.t()}
  def insert_user_entry(%{} = attrs) do
    %UserEntry{}
    |> UserEntry.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_user_entry_by_email(String.t()) :: UserEntry.t() | nil
  def get_user_entry_by_email(email) when is_binary(email) do
    UserEntry
    |> where(email: ^email)
    |> Repo.one()
  end

  @spec get_or_insert_user_entry(map()) :: {:ok, UserEntry.t()}
  def get_or_insert_user_entry(%{} = attrs) do
    case get_user_entry_by_email(attrs["email"]) do
      %UserEntry{} = entry -> {:ok, entry}
      nil -> insert_user_entry(attrs)
    end
  end
end
