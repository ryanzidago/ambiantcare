defmodule Ambiantcare.MedicalNotes.Templates do
  alias Ambiantcare.Repo
  alias Ambiantcare.MedicalNotes.Template
  alias Ambiantcare.Accounts.User

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Ecto.Query

  import Ecto.Query

  @spec templates(User.t()) :: list(Template.t())
  def templates(%User{} = user) do
    user
    |> templates_query()
    |> Repo.all()
  end

  @spec templates_query(User.t()) :: Query.t()
  def templates_query(%User{} = user) do
    from(r in Template, as: :t)
    |> where([t: t], t.user_id == ^user.id)
    |> order_by([t: t], desc: t.is_default, desc: t.title)
  end

  @spec change_user_default_template(User.t(), Template.t(), map()) :: Changeset.t()
  def change_user_default_template(%User{} = _user, %Template{} = template, attrs) do
    Template.changeset(template, attrs)
  end

  @spec update_user_default_template(
          user :: User.t(),
          previous_default_template :: Template.t(),
          default_template :: Template.t()
        ) :: {:ok, Template.t()} | {:error, Changeset.t()}
  def update_user_default_template(
        %User{} = user,
        %Template{is_default: true} = previous_default_template,
        %Template{is_default: false} = template_to_mark_as_default
      ) do
    previous_default_template =
      change_user_default_template(user, previous_default_template, %{is_default: false})

    default_template =
      change_user_default_template(user, template_to_mark_as_default, %{is_default: true})

    Multi.new()
    |> Multi.update(:previous_default_template, previous_default_template)
    |> Multi.update(:default_template, default_template)
    |> Repo.transaction()
  end
end
