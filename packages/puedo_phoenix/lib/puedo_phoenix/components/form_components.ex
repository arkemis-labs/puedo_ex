defmodule PuedoPhoenix.FormComponents do
  use Phoenix.Component

  attr :id, :any, default: nil
  attr :name, :string, required: true
  attr :value, :string, required: true
  attr :label, :string, default: nil
  attr :checked, :boolean, default: false
  attr :rest, :global

  def checkbox(assigns) do
    ~H"""
    <label for={@id || @name} class="flex items-center gap-2 cursor-pointer">
      <input
        type="checkbox"
        id={@id || @name}
        name={@name}
        value={@value}
        checked={@checked}
        class="checkbox checkbox-primary checkbox-sm"
        {@rest}
      />
      <span :if={@label}>{@label}</span>
    </label>
    """
  end

  attr :id, :any, default: nil
  attr :name, :string, required: true
  attr :value, :any, default: nil
  attr :label, :string, default: nil
  attr :prompt, :string, default: nil
  attr :options, :list, required: true
  attr :rest, :global, include: ~w(disabled multiple)

  def select(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id || @name}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select id={@id || @name} name={@name} class="w-full select" {@rest}>
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
    </div>
    """
  end
end
