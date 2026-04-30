defmodule PuedoPhoenix.RolesLive do
  use PuedoPhoenix, :live_view
  alias Puedo.Types.Role

  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:roles, Puedo.list_roles())
      |> assign(:form, to_form(%{"id" => "", "inherits" => ""}, as: "role"))

    {:ok, socket}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  defp apply_action(socket, :index), do: socket

  defp apply_action(socket, :new) do
    assign(socket, :form, to_form(%{"id" => "", "inherits" => ""}, as: "role"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path} puedo_prefix={@puedo_prefix}>
      <.header>
        Roles
        <:subtitle>RBAC role definitions</:subtitle>
        <:actions>
          <.button patch={@puedo_prefix <> "/roles/new"} variant="primary">New role</.button>
        </:actions>
      </.header>
      <.table id="roles" rows={@streams.roles}>
        <:col :let={{_id, role}} label="ID">{role.id}</:col>
        <:col :let={{_id, role}} label="Inherits">{Enum.join(role.inherits, ", ")}</:col>
        <:action :let={{_id, role}}>
          <.button phx-click="delete" phx-value-id={role.id}>
            Delete
          </.button>
        </:action>
      </.table>
      <.modal :if={@live_action == :new} id="role-modal" show patch={@puedo_prefix <> "/roles"}>
        <h3 class="text-lg font-bold">New role</h3>
        <.form for={@form} phx-submit="create" class="space-y-4 mt-4">
          <.input field={@form[:id]} label="ID" placeholder="admin" />
          <.input field={@form[:inherits]} label="Inherits (comma-separated)" />
          <div class="modal-action">
            <.button type="button" patch={@puedo_prefix <> "/roles"}>Cancel</.button>
            <.button type="submit" variant="primary">Create</.button>
          </div>
        </.form>
      </.modal>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Puedo.delete_role(id) do
      :ok ->
        {:noreply,
         socket
         |> stream_delete(:roles, %Role{id: id})
         |> put_flash(:info, "Role #{id} deleted")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Delete failed: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("create", %{"role" => params}, socket) do
    role = %Role{
      id: String.trim(params["id"] || ""),
      inherits: parse_inherits(params["inherits"] || "")
    }

    case Puedo.put_role(role) do
      :ok ->
        {:noreply,
         socket
         |> stream_insert(:roles, role, at: 0)
         |> put_flash(:info, "Role #{role.id} created")
         |> push_patch(to: socket.assigns.puedo_prefix <> "/roles")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:form, to_form(params, as: "role"))
         |> put_flash(:error, "Create failed: #{inspect(reason)}")}
    end
  end

  defp parse_inherits(""), do: []

  defp parse_inherits(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
