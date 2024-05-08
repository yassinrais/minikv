defmodule Minikv do
  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      {Cluster.Supervisor, [topologies, [name: Minikv.ClusterSupervisor]]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Minikv.Kv)
  end
end
