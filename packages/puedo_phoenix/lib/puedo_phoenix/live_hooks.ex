defmodule PuedoPhoenix.LiveHooks do
  import Phoenix.Component, only: [assign: 3]
  alias Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    prefix = socket.router.__puedo_prefix__()

    socket =
      socket
      |> assign(:puedo_prefix, prefix)
      |> assign(:current_path, nil)
      |> LiveView.attach_hook(:puedo_active_path, :handle_params, &set_current_path/3)

    {:cont, socket}
  end

  defp set_current_path(_params, url, socket) do
    {:cont, assign(socket, :current_path, URI.parse(url).path)}
  end
end
