defmodule Ambiantcare.Cldr do
  use Cldr,
    default_locale: "en",
    locales: ~w(en it),
    gettext: Ambiantcare.Gettext,
    otp_app: :ambiantcare,
    generate_docs: true,
    force_locale_download: true,
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
