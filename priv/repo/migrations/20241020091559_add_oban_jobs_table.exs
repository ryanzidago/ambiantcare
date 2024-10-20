defmodule Ambiantcare.Repo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  # https://hexdocs.pm/oban/installation.html
  def up do
    Oban.Migration.up(version: 12)
  end

  # We specify `version: 1` in `down`, ensuring that we'll roll all the way back down if
  # necessary, regardless of which version we've migrated `up` to.
  def down do
    Oban.Migration.down(version: 1)
  end
end
