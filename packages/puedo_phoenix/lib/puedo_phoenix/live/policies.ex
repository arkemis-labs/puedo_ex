defmodule PuedoPhoenix.PoliciesLive do
  use PuedoPhoenix, :live_view
  alias Puedo.Types.Policy

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:policies, Puedo.list_policies())
      |> assign(:roles, Puedo.list_roles())
      |> assign(:resources, Puedo.list_resources())
      |> assign(:conditions, Puedo.list_conditions())
      |> assign(:available_actions, [])
      |> assign(
        :form,
        to_form(%{"id" => "", "role" => "", "resource" => "", "actions" => [], "condition" => ""},
          as: "policy"
        )
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  defp apply_action(socket, :index), do: socket

  defp apply_action(socket, :new) do
    assign(
      socket,
      :form,
      to_form(%{"id" => "", "role" => "", "resource" => "", "actions" => [], "condition" => ""},
        as: "policy"
      )
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path} puedo_prefix={@puedo_prefix}>
      <.header>
        Policies
        <:subtitle>Policies definitions</:subtitle>
        <:actions>
          <.button patch={@puedo_prefix <> "/policies/new"} variant="primary">New policy</.button>
        </:actions>
      </.header>
      <.table id="policies" rows={@streams.policies}>
        <:col :let={{_id, policy}} label="Role">{policy.role}</:col>
        <:col :let={{_id, policy}} label="Resource">{policy.resource}</:col>
        <:col :let={{_id, policy}} label="Actions">{Enum.join(policy.actions, ", ")}</:col>
        <:col :let={{_id, policy}} label="Condition">{policy.condition}</:col>
        <:action :let={{_id, policy}}>
          <.button phx-click="delete" phx-value-id={policy.id}>
            Delete
          </.button>
        </:action>
      </.table>
      <.modal :if={@live_action == :new} id="policy-modal" show patch={@puedo_prefix <> "/policies"}>
        <h3 class="text-lg font-bold">New policy</h3>
        <.form for={@form} phx-submit="create" class="space-y-4 mt-4" phx-change="validate">
          <.select
            name="policy[role]"
            value={@form[:role].value}
            label="Role"
            options={Enum.map(@roles, &{&1.id, &1.id})}
            prompt="Choose role…"
          />
          <.select
            name="policy[resource]"
            value={@form[:resource].value}
            label="Resource"
            options={Enum.map(@resources, &{&1.id, &1.id})}
            prompt="Choose resource…"
          />
          <div class="fieldset mb-2">
            <span class="label mb-1">Actions</span>
            <div class="flex flex-col gap-1">
              <.checkbox
                :for={{label, value} <- @available_actions}
                name="policy[actions][]"
                value={value}
                label={label}
                checked={value in (@form[:actions].value || [])}
              />
              <p :if={@available_actions == []} class="text-sm text-base-content/60">
                Pick a resource to choose actions.
              </p>
            </div>
          </div>
          <.select
            name="policy[condition]"
            value={@form[:condition].value}
            label="Condition (optional)"
            options={Enum.map(@conditions, &{&1.name, &1.name})}
            prompt="None"
          />
          <div class="modal-action">
            <.button type="button" patch={@puedo_prefix <> "/policies"}>Cancel</.button>
            <.button type="submit" variant="primary">Create</.button>
          </div>
        </.form>
      </.modal>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", %{"policy" => params}, socket) do
    resource_id = params["resource"]

    available_actions =
      case Enum.find(socket.assigns.resources, &(&1.id == resource_id)) do
        nil -> []
        res -> Enum.map(res.actions, &{&1, &1})
      end

    {:noreply,
     socket
     |> assign(:form, to_form(params, as: "policy"))
     |> assign(:available_actions, available_actions)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Puedo.delete_policy(id) do
      :ok ->
        {:noreply,
         socket
         |> Phoenix.LiveView.stream_delete_by_dom_id(:policies, "policies-#{id}")
         |> put_flash(:info, "Policy #{id} deleted")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Delete failed: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("create", %{"policy" => params}, socket) do
    policy = %Policy{
      id: String.trim(params["id"] || ""),
      role: String.trim(params["role"] || ""),
      resource: String.trim(params["resource"] || ""),
      actions: params["actions"] || [],
      condition:
        case String.trim(params["condition"] || "") do
          "" -> nil
          v -> v
        end
    }

    case Puedo.put_policy(policy) do
      :ok ->
        {:noreply,
         socket
         |> stream_insert(:policies, policy, at: 0)
         |> put_flash(:info, "Policy #{policy.id} created")
         |> push_patch(to: socket.assigns.puedo_prefix <> "/policies")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:form, to_form(params, as: "policy"))
         |> put_flash(:error, "Create failed: #{inspect(reason)}")}
    end
  end
end
