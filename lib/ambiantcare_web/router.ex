defmodule AmbiantcareWeb.Router do
  use AmbiantcareWeb, :router

  import AmbiantcareWeb.UserAuth
  import AmbiantcareWeb.UserLocale, only: [put_locale: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AmbiantcareWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :put_locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AmbiantcareWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/:locale", AmbiantcareWeb do
    pipe_through :browser

    live "/", LandingPageLive, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", AmbiantcareWeb do
  #   pipe_through :api
  # end

  ## Authentication routes

  scope "/:locale", AmbiantcareWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      layout: {AmbiantcareWeb.Layouts, :authentication},
      on_mount: [{AmbiantcareWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/:locale", AmbiantcareWeb do
    pipe_through [:browser, :require_authenticated_user]

    # @ryanzidago redirect to consultations for now; route to be deprecated in the future
    get "/medical-notes", PageController, :medical_notes
    live "/consultations", ConsultationsLive, :index
    live "/consultations/:consultation_id", ConsultationsLive, :show

    live_session :require_authenticated_user,
      on_mount: [{AmbiantcareWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/:locale", AmbiantcareWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      layout: {AmbiantcareWeb.Layouts, :authentication},
      on_mount: [{AmbiantcareWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ambiantcare, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AmbiantcareWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
