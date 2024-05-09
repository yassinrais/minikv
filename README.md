### Minikv: A Distributed Key-Value Store for Elixir

Minikv is a lightweight, distributed key-value store library for Elixir, it provides a simple, intuitive API for storing and retrieving data, while handling the clustering and synchronization between the nodes.

### Features
* **Easy clustering**: Easily cluster nodes using the libcluster library, enabling smooth scaling of your key-value store.
* **Automatic synchronization**: Minikv automatically syncs data across all nodes, keeping your cluster up-to-date without any hassle.

### Usage

To use Minikv, simply add it to your Elixir project as a dependency, and then create a new instance of the `Minikv.Kvs` supervisor:
```elixir
defmodule MyKvs do
  use Minikv.Kvs
end
```

You can then use the get, put, and del functions to interact with your key-value store:
```elixir
iex> MyKvs.put(:my_key, "my_value")
:ok
iex> MyKvs.get(:my_key)
%Minikv.Kv{val: "my_value", node: :"node1:localhost", time: 123456789}
iex> MyKvs.del(:my_key)
:ok
```

### Configuration

Minikv uses the libcluster library to manage clustering, so you'll need to configure libcluster in your application. You can do this by adding the following configuration to your config.exs file:
```elixir
config :libcluster,
  topologies: [
    minikv: [
      strategy: Cluster.Strategy.Epmd
    ]
  ]
```
