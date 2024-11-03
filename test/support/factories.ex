defmodule Ambiantcare.Factories do
  use ExMachina.Ecto, repo: Ambiantcare.Repo
  use Ambiantcare.Factories.UserFactory
  use Ambiantcare.Factories.ConsultationFactory
  use Ambiantcare.Factories.TemplateFactory
end
