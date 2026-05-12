defmodule PuedoPhoenix.ConditionsLive do
  use PuedoPhoenix, :live_view
  alias Puedo.Types.Condition

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream_configure(:conditions, dom_id: &("conditions-#{&1.name}"))
      |> stream(:conditions, Puedo.list_conditions())
      |> assign(:form, empty_form())
      |> assign(:available_conditions, condition_options())
      |> assign(:selected_rules, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params), do: socket

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:form, empty_form())
    |> assign(:selected_rules, [])
  end

  defp apply_action(socket, :edit, %{"name" => name}) do
    condition = Enum.find(Puedo.list_conditions(), &(&1.name == name))

    form =
      to_form(
        %{
          "name" => condition.name,
          "op" => to_string(condition.op),
          "field" => condition.field || "",
          "value" => condition.value || "",
          "rules" => condition.rules
        },
        as: "condition"
      )

    selected = Map.new(condition.rules, &{&1, &1})

    available = condition_options() |> Enum.reject(fn {_label, value} -> value == name end)

    socket
    |> assign(:form, form)
    |> assign(:selected_rules, condition.rules)
    |> assign(:available_conditions, available)
    |> assign(:editing_condition, condition)
    |> send_update_selected(selected)
  end

  @impl true
  def render(assigns) do
     ~H"""
     <Layouts.app flash={@flash} current_path={@current_path} puedo_prefix={@puedo_prefix}>
       <.header>
         Conditions
         <:subtitle>Define conditions for role-based access control</:subtitle>
         <:actions>
           <.button patch={@puedo_prefix <> "/conditions/new"} variant="primary">New condition</.button>
         </:actions>
       </.header>
       <.table id="conditions" rows={@streams.conditions}>
         <:col :let={{_id, condition}} label="Name">{condition.name}</:col>
         <:col :let={{_id, condition}} label="Operation">{condition.op}</:col>
         <:col :let={{_id, condition}} label="Field">{condition.field}</:col>
         <:col :let={{_id, condition}} label="Value">{condition.value}</:col>
         <:col :let={{_id, condition}} label="Rules">{Enum.join(condition.rules, ", ")}</:col>
         <:action :let={{_id, condition}}>
           <.button patch={@puedo_prefix <> "/conditions/#{condition.name}/edit"} variant="primary">
             Edit
           </.button>
           <.button phx-click="delete" phx-value-name={condition.name}>
             Delete
           </.button>
         </:action>
       </.table>
       <.modal :if={@live_action in [:new, :edit]} id="condition-modal" show patch={@puedo_prefix <> "/conditions"}>
         <h3 class="text-lg font-bold">{if @live_action == :new, do: "New condition", else: "Edit condition"}</h3>
         <.form for={@form} phx-submit="save" class="space-y-4 mt-4">
           <input :if={@live_action == :edit} type="hidden" name="condition[original_name]" value={@form[:name].value} />
           <.input field={@form[:name]} label="Name" placeholder="my-condition" disabled={@live_action == :edit} required={true} />
           <.input type="select" field={@form[:op]}
             multiple={false} label="Operation"
             options={available_operations()} />
           <.input field={@form[:field]} label="Field" />
           <.input field={@form[:value]} label="Value" />
           <.live_component
             module={PuedoPhoenix.Components.MultiSelect}
             id="rules-select"
             label="Rules"
             input_name="condition[rules]"
             placeholder="Select rules..."
             options={@available_conditions}
             on_change={:rules_changed}
           />
           <div class="modal-action">
             <.button type="button" patch={@puedo_prefix <> "/conditions"}>Cancel</.button>
             <.button type="submit" variant="primary">{if @live_action == :new, do: "Create", else: "Update"}</.button>
           </div>
         </.form>
       </.modal>
     </Layouts.app>
     """
  end

  @impl true
  def handle_event("delete", %{"name" => name}, socket) do
    case Puedo.delete_condition(name) do
      :ok ->
        {:noreply,
         socket
         |> stream_delete(:conditions, %{name: name})
         |> put_flash(:info, "Condition #{name} deleted")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Delete failed: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("save", %{"condition" => params}, socket) do
    rules = socket.assigns.selected_rules

    name =
      if socket.assigns.live_action == :edit,
        do: params["original_name"] || params["name"],
        else: params["name"]

    condition =
      %{
        "name" => name,
        "op" => params["op"],
        "field" => params["field"],
        "value" => params["value"],
        "rules" => rules
      }
      |> Enum.into(%{}, fn
        {"op", v} -> {:op, String.to_existing_atom(v)}
        {"rules", v} -> {:rules, v}
        {k, v} -> {String.to_existing_atom(k), v}
      end)
      |> Condition.__struct__()

    case Puedo.put_condition(condition) do
      :ok ->
        verb = if socket.assigns.live_action == :new, do: "created", else: "updated"

        {:noreply,
         socket
         |> stream_insert(:conditions, condition, at: 0)
         |> assign(:available_conditions, condition_options())
         |> assign(:selected_rules, [])
         |> put_flash(:info, "Condition #{condition.name} #{verb}")
         |> push_patch(to: socket.assigns.puedo_prefix <> "/conditions")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:form, to_form(params, as: "condition"))
         |> put_flash(:error, "Save failed: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_info({:rules_changed, rules}, socket) do
    {:noreply, assign(socket, :selected_rules, rules)}
  end

  defp send_update_selected(socket, selected) do
    send_update(PuedoPhoenix.Components.MultiSelect, id: "rules-select", selected: selected)
    socket
  end

  defp empty_form(), do:
    to_form(%{"name" => "", "op" => "", "field" => "", "value" => "", "rules" => []}, as: "condition")

  defp condition_options(params \\ %{}) do
    Puedo.list_conditions() |> Enum.map(&{&1.name, &1.name})
  end

  defp available_operations(), do:
    [
      {"Equal", :eq},
      {"Greater than", :gt},
      {"Less than", :lt},
      {"Greater than or equal", :gte},
      {"Less than or equal", :lte},
      {"In", :in},
      {"And", :and},
      {"Or", :or},
      {"Not", :not}
    ]


end
