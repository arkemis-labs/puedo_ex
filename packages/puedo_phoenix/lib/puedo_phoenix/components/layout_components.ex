defmodule PuedoPhoenix.LayoutComponents do
  use Phoenix.Component

  import PuedoPhoenix.CoreComponents, only: [icon: 1]

  attr :prefix, :string, default: ""
  attr :current_path, :string, default: nil

  def sidebar(assigns) do
    ~H"""
    <nav
      class="w-56 flex flex-col pr-3 py-5 space-y-1 bg-sidebar border-r border-border"
      aria-label="sidebar"
    >
      <.link navigate={@prefix <> "/"} aria-label="Puedo home" class="mb-4 pl-5 pr-3">
        <span class="text-primary font-bold text-xl tracking-tight">Puedo</span>
      </.link>

      <.sidebar_item
        navigate={@prefix <> "/"}
        icon="hero-home"
        label="Dashboard"
        current_path={@current_path}
        exact
      />
      <.sidebar_item
        navigate={@prefix <> "/roles"}
        icon="hero-shield-check"
        label="Roles"
        current_path={@current_path}
      />
      <.sidebar_item
        navigate={@prefix <> "/resources"}
        icon="hero-cube"
        label="Resources"
        current_path={@current_path}
      />
      <.sidebar_item
        navigate={@prefix <> "/policies"}
        icon="hero-document-text"
        label="Policies"
        current_path={@current_path}
      />
      <.sidebar_item
        navigate={@prefix <> "/conditions"}
        icon="hero-funnel"
        label="Conditions"
        current_path={@current_path}
      />
      <.sidebar_item
        navigate={@prefix <> "/tester"}
        icon="hero-beaker"
        label="Tester"
        current_path={@current_path}
      />
    </nav>
    """
  end

  attr :navigate, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :current_path, :string, default: nil
  attr :exact, :boolean, default: false

  defp sidebar_item(assigns) do
    assigns =
      assign(assigns, :active?, active?(assigns.current_path, assigns.navigate, assigns.exact))

    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "flex items-center border-l-5 border-transparent gap-3 px-3 py-2 rounded-r-sm text-sm font-medium",
        if(@active?,
          do: "bg-base-300 border-l-primary text-primary",
          else: "hover:bg-base-300"
        )
      ]}
      aria-current={@active? && "page"}
    >
      <.icon name={@icon} class="size-5" />
      <span>{@label}</span>
    </.link>
    """
  end

  defp active?(nil, _href, _exact), do: false

  defp active?(path, href, true) do
    normalize(path) == normalize(href)
  end

  defp active?(path, href, false) do
    href = String.trim_trailing(href, "/")
    path = String.trim_trailing(path, "/")

    path == href or String.starts_with?(path, href <> "/")
  end

  defp normalize(""), do: "/"
  defp normalize("/"), do: "/"
  defp normalize(path), do: String.trim_trailing(path, "/")
end
