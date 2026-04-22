defmodule PuedoPhoenix.ConditionController do
  use Phoenix.Controller, formats: [:json]

  alias Puedo.Types.Condition

  def index(conn, _params) do
    conditions = Puedo.list_conditions()
    json(conn, %{data: Enum.map(conditions, &condition_to_json/1)})
  end

  def create(conn, %{"name" => name, "op" => _op} = params) do
    case build_condition(name, params) do
      {:ok, condition} ->
        case Puedo.put_condition(condition) do
          :ok ->
            conn
            |> put_status(:created)
            |> json(%{data: condition_to_json(condition)})

          {:error, reason} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: to_string(reason)})
        end

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "missing required fields: name, op"})
  end

  def delete(conn, %{"id" => name}) do
    case Puedo.delete_condition(name) do
      :ok ->
        send_resp(conn, :no_content, "")

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  defp build_condition(name, %{"op" => op} = data) do
    with {:ok, op_atom} <- parse_op(op),
         {:ok, condition} <- build_condition_body(name, op_atom, data) do
      {:ok, condition}
    end
  end

  defp build_condition_body(name, op, %{"rules" => rules}) when is_list(rules) do
    built =
      Enum.reduce_while(rules, {:ok, []}, fn rule, {:ok, acc} ->
        case build_condition(rule["name"] || name, rule) do
          {:ok, c} -> {:cont, {:ok, [c | acc]}}
          {:error, _} = err -> {:halt, err}
        end
      end)

    case built do
      {:ok, rules} -> {:ok, %Condition{name: name, op: op, rules: Enum.reverse(rules)}}
      {:error, _} = err -> err
    end
  end

  defp build_condition_body(name, op, data) do
    {:ok,
     %Condition{
       name: name,
       op: op,
       field: data["field"],
       value: parse_value(data["value"])
     }}
  end

  defp parse_op(op) when is_binary(op) do
    {:ok, String.to_existing_atom(op)}
  rescue
    ArgumentError -> {:error, "invalid op: #{op}"}
  end

  defp parse_value(%{"ref" => path}), do: %{ref: path}
  defp parse_value(value), do: value

  # todo: derive from Condition?
  defp condition_to_json(%Condition{rules: rules} = condition) when is_list(rules) do
    %{
      name: condition.name,
      op: Atom.to_string(condition.op),
      rules: Enum.map(rules, &condition_to_json/1)
    }
  end

  defp condition_to_json(%Condition{} = condition) do
    %{
      name: condition.name,
      op: Atom.to_string(condition.op),
      field: condition.field,
      value: serialize_value(condition.value)
    }
  end

  defp serialize_value(%{ref: path}), do: %{"ref" => path}
  defp serialize_value(value), do: value
end
