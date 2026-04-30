defmodule PuedoPhoenix.Layouts do
  use Phoenix.Component
  use Gettext, backend: PuedoPhoenix.Gettext

  import Phoenix.Controller, only: [get_csrf_token: 0]
  import PuedoPhoenix.CoreComponents

  alias Phoenix.LiveView.JS
  alias PuedoPhoenix.LayoutComponents

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_scope, :map, default: nil
  attr :current_path, :string, default: nil
  attr :puedo_prefix, :string, default: ""
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="flex min-h-screen">
      <LayoutComponents.sidebar prefix={@puedo_prefix} current_path={@current_path} />

      <div class="flex-1 flex flex-col">
        <main class="px-4 py-8 sm:px-6 lg:px-8">
          {render_slot(@inner_block)}
        </main>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  defp asset_path(conn, asset) when asset in [:css, :js] do
    hash = PuedoPhoenix.Assets.current_hash(asset)
    prefix = conn.private.phoenix_router.__puedo_prefix__()

    Phoenix.VerifiedRoutes.unverified_path(
      conn,
      conn.private.phoenix_router,
      "#{prefix}/#{asset}-#{hash}"
    )
  end
end
