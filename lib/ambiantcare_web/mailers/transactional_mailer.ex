defmodule AmbiantcareWeb.TransactionalMailer do
  @moduledoc """
  Mailer for transactional emails (e.g. welcome emails, password resets).
  """
  use Swoosh.Mailer, otp_app: :ambiantcare
end
