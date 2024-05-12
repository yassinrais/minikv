Minikv
=======
[![Build Status](https://github.com/yassinrais/minikv/workflows/minikv/badge.svg)](https://github.com/yassinrais/minikv/actions)
[![Last Updated](https://img.shields.io/github/last-commit/yassinrais/minikv.svg)](https://github.com/yassinrais/minikv/commits/master)
[![MIT License](https://img.shields.io/github/license/yassinrais/minikv)](https://github.com/yassinrais/minikv/blob/main/LICENSE)
[![Coveralls](https://coveralls.io/repos/yassinrais/minikv/badge.svg?branch=main)](https://coveralls.io/r/yassinrais/minikv?branch=master)

Minikv: A lightweight Elixir library for building distributed key-value stores (:ets) featuring asynchronous replication between nodes,
offering a simple way to store and retrieve key-value pairs, with advanced features like key expiration, locking, and persistence.

Installation
------------

To use Minikv in your Elixir project, add it as a dependency in your `mix.exs` file:

```elixir
defp deps do
  [
    {:minikv, "~> 0.1.1"}
  ]
end
```


Then run `mix deps.get` to fetch the dependency.

Example Usage
-----

### Storing a value

To store a value in the registry, you can use the `Minikv.Registry.put/3` function:

```elixir
iex> Minikv.Registry.put(WalletExKv, :my_balance, "100$")
%Minikv.Kv{value: "100$"}
```

### Retrieving a value

To retrieve a value from the registry, you can use the `Minikv.Registry.get/2` function:

```elixir
iex> Minikv.Registry.get(WalletExKv, :my_balance)
%Minikv.Kv{value: "100$", node: :node1, time: 123456789}
```

### Deleting a value

To delete a value from the registry, you can use the `Minikv.Registry.delete/2` function:

```elixir
iex> Minikv.Registry.delete(WalletExKv, :my_balance)
%Minikv.Kv{value: "100$"}
```

### Locking a key

Minikv allows you to lock a key in the registry, preventing other nodes from modifying it. To lock a key, you can use the `Minikv.Registry.lock/2` function:

```elixir
iex> Minikv.Registry.lock(WalletExKv, :my_balance)
%Minikv.Kv{value: "100$", lock: true}
```

### Unlocking a key

To unlock a key in the registry, you can use the `Minikv.Registry.unlock/2` function:

```elixir
iex> Minikv.Registry.unlock(WalletExKv, :my_balance)
%Minikv.Kv{value: "100$", lock: nil}
```

### Persisting a key-value

To persist a key-value in the registry, you can use the `Minikv.Registry.persist/2` function:

```elixir
iex> Minikv.Registry.persist(WalletExKv, :my_balance)
%Minikv.Kv{value: "100$", exp: nil}
```

Advanced Usage
--------------

### Customizing key-value options

When storing a value in the registry, you can customize the options associated with the key-value pair. The `Minikv.Registry.put/3` function accepts a list of options as the third argument:

```elixir
iex> Minikv.Registry.put(WalletExKv, :my_balance, [value: "100$", ttl: 1000])
%Minikv.Kv{value: "100$", exp: 123_456_789_100}
```

In the above example, we've set the `ttl` (time-to-live) of the key-value pair to 1000 milliseconds. Other available options include:

* `:lock` - A boolean value indicating whether the key should be locked.
* `:persist` - A boolean value indicating whether the key-value should be persisted.

### Handling errors

The functions provided by Minikv can return errors in certain situations. For example, if you try to retrieve a value for a key that doesn't exist, the `Minikv.Registry.get/2` function will return `nil`.

```elixir
iex> Minikv.Registry.get(WalletExKv, :nonexistent_key)
nil
```

Similarly, if you try to lock a key that's already locked by another process, the `Minikv.Registry.lock/2` function will return `{:error, :locked}`.

```elixir
iex> Minikv.Registry.lock(WalletExKv, :my_balance)
%Minikv.Kv{value: "100$", lock: true}
iex> Minikv.Registry.lock(WalletExKv, :my_balance)
{:error, :locked}
```
