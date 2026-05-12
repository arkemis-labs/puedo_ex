defmodule PuedoPhoenix.Router do
  defmacro puedo_dashboard(path, opts \\ []) do
    scope =
      quote bind_quoted: [path: path, opts: opts] do
        login? = Keyword.get(opts, :login, false)
        import Phoenix.LiveView.Router, only: [live: 3, live_session: 3]

        scope path, alias: false, as: :puedo do
          live_session :puedo_admin,
            root_layout: {PuedoPhoenix.Layouts, :root},
            on_mount: PuedoPhoenix.LiveHooks do
            get "/css-:md5", PuedoPhoenix.Assets, :css, as: :puedo_asset
            get "/js-:md5", PuedoPhoenix.Assets, :js, as: :puedo_asset
            live "/", PuedoPhoenix.DashboardLive, :index
            live "/roles", PuedoPhoenix.RolesLive, :index
            live "/roles/new", PuedoPhoenix.RolesLive, :new
            live "/policies", PuedoPhoenix.PoliciesLive, :index
            live "/policies/new", PuedoPhoenix.PoliciesLive, :new
            live "/conditions", PuedoPhoenix.ConditionsLive, :index
            live "/conditions/new", PuedoPhoenix.ConditionsLive, :new
            live "/conditions/:name/edit", PuedoPhoenix.ConditionsLive, :edit
            live "/resources", PuedoPhoenix.ResourcesLive, :index
            live "/resources/new", PuedoPhoenix.ResourcesLive, :new
            live "/tester", PuedoPhoenix.TesterLive, :index

            if login? do
              live "/login", PuedoPhoenix.LoginLive, :index
            end
          end
        end
      end

    quote do
      unquote(scope)

      unless Module.get_attribute(__MODULE__, :puedo_prefix) do
        @puedo_prefix Phoenix.Router.scoped_path(__MODULE__, path)
                      |> String.replace_suffix("/", "")
        def __puedo_prefix__, do: @puedo_prefix
      end
    end
  end

  defmacro puedo_api(path) do
    quote bind_quoted: [path: path] do
      scope path <> "/api", alias: false, as: :puedo_api do
        get "/snapshot", PuedoPhoenix.SnapshotController, :show
        get "/version", PuedoPhoenix.SnapshotController, :version

        resources "/roles", PuedoPhoenix.RoleController, only: [:index, :create, :delete]
        resources "/policies", PuedoPhoenix.PolicyController, only: [:index, :create, :delete]

        resources "/conditions", PuedoPhoenix.ConditionController,
          only: [:index, :create, :delete]

        resources "/resources", PuedoPhoenix.ResourceController, only: [:index, :create, :delete]
      end
    end
  end
end
