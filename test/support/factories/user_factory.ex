defmodule Ambiantcare.Factories.UserFactory do
  alias Ambiantcare.Accounts.User

  defmacro __using__(_opts) do
    quote do
      def user_factory(attrs \\ %{}) do
        email =
          Map.get_lazy(attrs, :email, fn -> sequence(:email, &"email-#{&1}@example.com") end)

        hashed_password = Map.get(attrs, :hashed_password, "hello, world!")

        user = %User{
          email: email,
          hashed_password: hashed_password
        }

        user
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
