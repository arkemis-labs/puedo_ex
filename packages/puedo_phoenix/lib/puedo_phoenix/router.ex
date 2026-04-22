defmodule PuedoPhoenix.Router do
  defmacro puedo(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      dashboard? = Keyword.get(opts, :dashboard, false)
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

      scope path <> "/api", alias: false, as: :puedo_api do
        get "/snapshot", PuedoPhoenix.SnapshotController, :show
        get "/version", PuedoPhoenix.SnapshotController, :version

        resources "/roles", PuedoPhoenix.RoleController,
          only: [:index, :create, :delete]

        resources "/policies", PuedoPhoenix.PolicyController,
          only: [:index, :create, :delete]

        resources "/conditions", PuedoPhoenix.ConditionController,
          only: [:index, :create, :delete]

        resources "/resources", PuedoPhoenix.ResourceController,
          only: [:index, :create, :delete]
      end
    end
  end
end
