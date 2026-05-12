defmodule PuedoPhoenix.Components.MultiSelect do
  @moduledoc """
  A multi-select popover LiveComponent with search and chip display.

  ## Usage

      <.live_component
        module={PuedoPhoenix.Components.MultiSelect}
        id="rules-select"
        label="Rules"
        input_name="condition[rules]"
        placeholder="Select rules..."
        options={@available_conditions}
      />

  Options are `{label, value}` tuples. Selected values are submitted
  as hidden inputs with the given `input_name` (with `[]` appended).
  """
  use Phoenix.LiveComponent
  alias Phoenix.LiveView.JS

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:selected, fn -> %{} end)
      |> assign_new(:filter, fn -> "" end)
      |> assign_new(:disabled, fn -> false end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="fieldset mb-2">
      <span :if={@label} class="label mb-1">{@label}</span>

      <input :for={{value, _label} <- @selected} type="hidden" name={"#{@input_name}[]"} value={value} />

      <div>
        <div
          class="select w-full h-auto flex flex-wrap items-center gap-1 cursor-pointer py-2"
          phx-click={toggle_popover(@id)}
          disabled={@disabled}
        >
          <span :if={@selected == %{}} class="opacity-50 select-none">{@placeholder}</span>
          <span :for={{value, label} <- @selected} class="badge badge-primary gap-1">
            {label}
            <span
              class="cursor-pointer"
              phx-click="remove"
              phx-value-value={value}
              phx-target={@myself}
            >✕</span>
          </span>
        </div>

        <div
          id={"#{@id}-popover"}
          class="hidden border border-base-300 bg-base-100 rounded-b-lg shadow-md -mt-1 flex flex-col gap-2"
          phx-click-away={JS.hide(to: "##{@id}-popover")}
        >
          <div class="p-2 pt-3 shrink-0">
            <input
              type="text"
              class="input input-sm w-full"
              placeholder="Search..."
              phx-keyup="filter"
              phx-target={@myself}
              value={@filter}
              autocomplete="off"
            />
          </div>
          <div class="overflow-y-auto px-2 pb-2 flex flex-col gap-1 max-h-24">
            <p :if={@options == []} class="text-sm text-base-content/50 p-2">
              No options available.
            </p>
            <p :if={@options != [] && filtered_options(@options, @filter) == []} class="text-sm text-base-content/50 p-2">
              No matches found.
            </p>
            <label
              :for={{label, value} <- filtered_options(@options, @filter)}
              class="flex items-center gap-2 cursor-pointer px-2 py-1 hover:bg-base-200 rounded"
            >
              <input
                type="checkbox"
                id={"#{@id}-check-#{value}"}
                class="checkbox checkbox-sm"
                checked={Map.has_key?(@selected, to_string(value))}
                phx-click={JS.push("toggle", target: @myself, value: %{value: to_string(value), label: label})}
              />
              <span class="text-sm">{label}</span>
            </label>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle", %{"value" => value, "label" => label}, socket) do
    selected = socket.assigns.selected

    selected =
      if Map.has_key?(selected, value),
        do: Map.delete(selected, value),
        else: Map.put(selected, value, label)

    notify_parent(socket, selected)
    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event("remove", %{"value" => value}, socket) do
    selected = Map.delete(socket.assigns.selected, value)
    notify_parent(socket, selected)
    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event("filter", %{"value" => text}, socket) do
    {:noreply, assign(socket, :filter, text)}
  end

  defp notify_parent(socket, selected) do
    if on_change = socket.assigns[:on_change] do
      send(self(), {on_change, Map.keys(selected)})
    end
  end

  defp toggle_popover(id) do
    JS.toggle(to: "##{id}-popover")
  end

  defp filtered_options(options, ""), do: options

  defp filtered_options(options, filter) do
    filter = String.downcase(filter)

    Enum.filter(options, fn {label, _value} ->
      String.contains?(String.downcase(label), filter)
    end)
  end
end
