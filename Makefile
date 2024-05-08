# Run nodes
a:
	iex --name a@127.0.0.1 --cookie secret -S mix
b:
	iex --name b@127.0.0.1 --cookie secret -S mix