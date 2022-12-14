defmodule EctoRange.Date.DataCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      alias TestApp.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import EctoRange.Date.DataCase
    end
  end

  setup tags do
    EctoRange.Date.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    repo_pid = Ecto.Adapters.SQL.Sandbox.start_owner!(TestApp.Repo, shared: not tags[:async])

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(repo_pid) end)
  end
end
