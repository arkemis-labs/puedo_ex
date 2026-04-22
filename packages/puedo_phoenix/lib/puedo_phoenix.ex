defmodule PuedoPhoenix do
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def live_view do
    quote do
      use Phoenix.LiveView
      use Gettext, backend: PuedoPhoenix.Gettext

      import Phoenix.HTML
      import PuedoPhoenix.CoreComponents

      alias Phoenix.LiveView.JS
      alias PuedoPhoenix.Layouts

      use Phoenix.VerifiedRoutes,
        endpoint: Application.compile_env(:puedo_phoenix, :endpoint),
        router: Application.compile_env(:puedo_phoenix, :router),
        statics: PuedoPhoenix.static_paths()
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Application.compile_env(:puedo_phoenix, :endpoint),
        router: Application.compile_env(:puedo_phoenix, :router),
        statics: PuedoPhoenix.static_paths()
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
