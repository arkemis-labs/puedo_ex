defmodule PuedoPhoenix.ResourcesLive do
  use PuedoPhoenix, :live_view
  alias Puedo.Types.Resource

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:resources, Puedo.list_resources())
      |> assign(:form, empty_form())

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  defp apply_action(socket, :index), do: socket
  defp apply_action(socket, :new), do: assign(socket, :form, empty_form())

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path} puedo_prefix={@puedo_prefix}>
      <.header>
        Resources
        <:subtitle>Resource definitions and their actions</:subtitle>
        <:actions>
          <.button patch={@puedo_prefix <> "/resources/new"} variant="primary">
            New resource
          </.button>
        </:actions>
      </.header>
      <.table id="resources" rows={@streams.resources}>
        <:col :let={{_id, resource}} label="ID">{resource.id}</:col>
        <:col :let={{_id, resource}} label="Actions">{Enum.join(resource.actions, ", ")}</:col>
        <:col :let={{_id, resource}} label="Relations">{Enum.join(resource.relations, ", ")}</:col>
      </.table>
      <.modal
        :if={@live_action == :new}
        id="resource-modal"
        show
        patch={@puedo_prefix <> "/resources"}
      >
        <h3 class="text-lg font-bold">New resource</h3>
        <.form for={@form} phx-submit="create" class="space-y-4 mt-4">
          <.input field={@form[:id]} label="ID" placeholder="document" />
          <.input
            field={@form[:actions]}
            label="Actions (comma-separated)"
            placeholder="read, write, delete"
          />
          <.input
            field={@form[:relations]}
            label="Relations (comma-separated)"
            placeholder="owner, viewer"
          />
          <div class="modal-action">
            <.button type="button" patch={@puedo_prefix <> "/resources"}>Cancel</.button>
            <.button type="submit" variant="primary">Create</.button>
          </div>
        </.form>
      </.modal>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("create", %{"resource" => params}, socket) do
    resource = %Resource{
      id: String.trim(params["id"] || ""),
      actions: parse_list(params["actions"] || ""),
      relations: parse_list(params["relations"] || "")
    }

    case Puedo.put_resource(resource) do
      :ok ->
        {:noreply,
         socket
         |> stream_insert(:resources, resource, at: 0)
         |> put_flash(:info, "Resource #{resource.id} created")
         |> push_patch(to: socket.assigns.puedo_prefix <> "/resources")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:form, to_form(params, as: "resource"))
         |> put_flash(:error, "Create failed: #{inspect(reason)}")}
    end
  end

  defp empty_form do
    to_form(%{"id" => "", "actions" => "", "relations" => ""}, as: "resource")
  end

  defp parse_list(""), do: []

  defp parse_list(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
