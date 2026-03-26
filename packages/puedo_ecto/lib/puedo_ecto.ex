defmodule PuedoEcto do
  @moduledoc """
  Documentation for `PuedoEcto`.
  """

  @doc """
  Get the migrations path for PuedoEcto. This can be used by your own repo to run the migrations against it.

  """
  def migrations_path do
     Application.app_dir(:puedo_ecto, "priv/repo/migrations")
  end
end
