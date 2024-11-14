defmodule Ambiantcare.Consultations do
  alias Ambiantcare.Consultations.Consultation
  alias Ambiantcare.Accounts.User
  alias Ambiantcare.Repo

  alias Ecto.Changeset

  import Ecto.Query

  @spec create_or_update_consultation(User.t(), Consultation.t(), map()) ::
          {:ok, Consultation.t()}
          | {:error, Changeset.t()}
  def create_or_update_consultation(
        %User{} = _current_user,
        %Consultation{} = consultation,
        %{} = attrs
      ) do
    consultation
    |> Consultation.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @spec get_consultation(User.t(), Ecto.UUID.t()) :: Consultation.t() | nil
  def get_consultation(%User{} = user, id) do
    from(cons in Consultation, as: :cons)
    |> where([cons: cons], cons.user_id == ^user.id)
    |> where([cons: cons], cons.id == ^id)
    |> Repo.one()
  end

  @spec get_latest_consultation(User.t()) :: Consultation.t() | nil
  def get_latest_consultation(%User{} = user) do
    user
    |> list_consultations_query()
    |> limit(1)
    |> Repo.one()
  end

  @spec list_consultations(User.t()) :: list(Consultation.t())
  def list_consultations(%User{} = user) do
    user
    |> list_consultations_query()
    |> Repo.all()
  end

  @spec list_consultations_query(User.t()) :: Ecto.Query.t()
  def list_consultations_query(%User{} = user) do
    from(cons in Consultation, as: :cons)
    |> where([cons: cons], cons.user_id == ^user.id)
    |> order_by([cons: cons], desc: cons.inserted_at)
  end

  @spec delete_consultation(User.t(), Consultation.t()) :: {:ok, Consultation.t()}
  def delete_consultation(%User{} = user, %Consultation{} = consultation)
      when user.id == consultation.user_id do
    Repo.delete(consultation)
  end

  @spec update_title(User.t(), Consultation.t(), String.t()) ::
          {:ok, Consultation.t()} | {:error, Changeset.t()}
  def update_title(%User{} = _user, %Consultation{} = consultation, title) do
    consultation
    |> Consultation.update_title_changeset(%{title: title})
    |> Repo.update()
  end
end
