defmodule PuedoPhoenix.Router do
  defmacro puedo_dashboard(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      dashboard? = Keyword.get(opts, :dashboard, true)
      login? = Keyword.get(opts, :login, false)

      if dashboard? do
        import Phoenix.LiveView.Router, only: [live: 3, live_session: 3]

        scope path, alias: false, as: :puedo do
          live_session :puedo_admin, root_layout: {PuedoPhoenix.Layouts, :admin} do
            live "/", PuedoPhoenix.DashboardLive, :index
            live "/roles", PuedoPhoenix.RolesLive, :index
            live "/policies", PuedoPhoenix.PoliciesLive, :index
            live "/conditions", PuedoPhoenix.ConditionsLive, :index
            live "/resources", PuedoPhoenix.ResourcesLive, :index
            live "/tester", PuedoPhoenix.TesterLive, :index

            if login? do
              live "/login", PuedoPhoenix.LoginLive, :index
            end
          end
        end
      end

      scope path <> "/api", PuedoPhoenix, as: :puedo_api do
        get "/snapshot", SnapshotController, :show
        get "/version", SnapshotController, :version

        resources "/roles", RoleController, only: [:index, :create, :delete]
        resources "/policies", PolicyController, only: [:index, :create, :delete]
        resources "/conditions", ConditionController, only: [:index, :create, :delete]
        resources "/resources", ResourceController, only: [:index, :create, :delete]
      end
    end
  end
end
