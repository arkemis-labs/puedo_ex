defmodule PuedoPhoenix.Components.MultiSelect do
  @moduledoc """
  A multi-select dropdown LiveComponent with search and chip display.

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
      |> assign_new(:selected, fn -> MapSet.new() end)
      |> assign_new(:filter, fn -> "" end)
      |> assign_new(:disabled, fn -> false end)

    filtered = filter_options(socket.assigns.options, socket.assigns.filter)

    {:ok, assign(socket, :filtered_options, filtered)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="fieldset mb-2">
      <span :if={@label} class="label mb-1">{@label}</span>

      <input :for={val <- @selected} type="hidden" name={"#{@input_name}[]"} value={val} />

      <div>
        <div
          class="select w-full h-auto min-h-12 flex flex-wrap items-center gap-1 cursor-pointer py-2"
          phx-click={toggle_dropdown(@id)}
          disabled={@disabled}
        >
          <span :if={MapSet.size(@selected) == 0} class="opacity-50 select-none">{@placeholder}</span>
          <span :for={val <- @selected} class="badge badge-primary gap-1">
            {val}
            <span
              class="cursor-pointer"
              phx-click="remove"
              phx-value-value={val}
              phx-target={@myself}
            >✕</span>
          </span>
        </div>

        <div
          id={"#{@id}-dropdown"}
          class="hidden border border-base-300 bg-base-100 rounded-b-lg shadow-md -mt-1 z-50 relative"
          phx-click-away={JS.hide(to: "##{@id}-dropdown")}
        >
          <div class="p-2">
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
          <ul class="max-h-48 overflow-y-auto px-2 pb-2">
            <li :if={@filtered_options == []} class="text-sm text-base-content/50 p-2">
              No matches found.
            </li>
            <li :for={{label, value} <- @filtered_options} class="py-0.5">
              <label class="flex items-center gap-2 cursor-pointer px-2 py-1 hover:bg-base-200 rounded">
                <input
                  type="checkbox"
                  class="checkbox checkbox-sm"
                  checked={MapSet.member?(@selected, value)}
                  phx-click="toggle"
                  phx-value-value={value}
                  phx-target={@myself}
                />
                <span class="text-sm">{label}</span>
              </label>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle", %{"value" => value}, socket) do
    selected = toggle_selected(socket.assigns.selected, value)
    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event("remove", %{"value" => value}, socket) do
    {:noreply, assign(socket, :selected, MapSet.delete(socket.assigns.selected, value))}
  end

  def handle_event("filter", %{"value" => text}, socket) do
    filtered = filter_options(socket.assigns.options, text)
    {:noreply, assign(socket, filter: text, filtered_options: filtered)}
  end

  defp toggle_selected(selected, value) do
    if MapSet.member?(selected, value),
      do: MapSet.delete(selected, value),
      else: MapSet.put(selected, value)
  end

  defp filter_options(options, ""), do: options

  defp filter_options(options, text) do
    text = String.downcase(text)

    Enum.filter(options, fn {label, _value} ->
      String.contains?(String.downcase(label), text)
    end)
  end

  defp toggle_dropdown(id) do
    JS.toggle(to: "##{id}-dropdown")
  end
end
