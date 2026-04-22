defmodule PuedoPhoenix.ConditionControllerTest do
  use PuedoPhoenix.ConnCase

  setup do
    for condition <- Puedo.list_conditions() do
      Puedo.delete_condition(condition.name)
    end

    :ok
  end

  describe "GET /api/conditions" do
    test "returns empty list when no conditions", %{conn: conn} do
      conn = get(conn, ~p"/api/conditions")
      assert json_response(conn, 200) == %{"data" => []}
    end

    test "returns existing leaf condition", %{conn: conn} do
      Puedo.put_condition(%Puedo.Types.Condition{
        name: "is_owner",
        op: :eq,
        field: "resource.owner_id",
        value: %{ref: "subject.id"}
      })

      conn = get(conn, ~p"/api/conditions")
      data = json_response(conn, 200)["data"]

      assert [
               %{
                 "name" => "is_owner",
                 "op" => "eq",
                 "field" => "resource.owner_id",
                 "value" => %{"ref" => "subject.id"}
               }
             ] = data
    end

    test "returns existing composite condition", %{conn: conn} do
      Puedo.put_condition(%Puedo.Types.Condition{
        name: "owner_and_published",
        op: :and,
        rules: [
          %Puedo.Types.Condition{
            name: "owner_and_published",
            op: :eq,
            field: "resource.owner_id",
            value: %{ref: "subject.id"}
          },
          %Puedo.Types.Condition{
            name: "owner_and_published",
            op: :eq,
            field: "resource.published",
            value: true
          }
        ]
      })

      conn = get(conn, ~p"/api/conditions")
      [data] = json_response(conn, 200)["data"]

      assert data["op"] == "and"
      assert length(data["rules"]) == 2
    end
  end

  describe "POST /api/conditions" do
    test "creates a leaf condition", %{conn: conn} do
      conn =
        post(conn, ~p"/api/conditions", %{
          name: "is_owner",
          op: "eq",
          field: "resource.owner_id",
          value: %{ref: "subject.id"}
        })

      assert %{
               "data" => %{
                 "name" => "is_owner",
                 "op" => "eq",
                 "field" => "resource.owner_id",
                 "value" => %{"ref" => "subject.id"}
               }
             } = json_response(conn, 201)

      assert %Puedo.Types.Condition{name: "is_owner", op: :eq} =
               Enum.find(Puedo.list_conditions(), &(&1.name == "is_owner"))
    end

    test "creates a composite condition with nested rules", %{conn: conn} do
      conn =
        post(conn, ~p"/api/conditions", %{
          name: "owner_and_published",
          op: "and",
          rules: [
            %{op: "eq", field: "resource.owner_id", value: %{ref: "subject.id"}},
            %{op: "eq", field: "resource.published", value: true}
          ]
        })

      body = json_response(conn, 201)["data"]
      assert body["op"] == "and"
      assert length(body["rules"]) == 2

      stored = Enum.find(Puedo.list_conditions(), &(&1.name == "owner_and_published"))
      assert stored.op == :and
      assert length(stored.rules) == 2
    end

    test "returns error when required fields are missing", %{conn: conn} do
      conn = post(conn, ~p"/api/conditions", %{name: "bad"})
      assert json_response(conn, 400)["error"] =~ "missing"
    end

    test "returns error when op is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/api/conditions", %{
          name: "bad",
          op: "nonsense_op_that_is_not_an_atom",
          field: "x",
          value: 1
        })

      assert json_response(conn, 400)["error"] =~ "invalid op"
    end
  end

  describe "DELETE /api/conditions/:id" do
    test "deletes an existing condition", %{conn: conn} do
      Puedo.put_condition(%Puedo.Types.Condition{
        name: "temp",
        op: :eq,
        field: "x",
        value: 1
      })

      conn = delete(conn, ~p"/api/conditions/temp")
      assert response(conn, 204)

      assert Puedo.list_conditions() |> Enum.find(&(&1.name == "temp")) == nil
    end
  end
end
