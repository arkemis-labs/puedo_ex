defmodule PuedoPhoenix do
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def live_view do
    quote do
      use Phoenix.LiveView
      alias PuedoPhoenix.Layouts
      import PuedoPhoenix.CoreComponents
      import PuedoPhoenix.FormComponents
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
