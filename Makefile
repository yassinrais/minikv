# Run nodes
a:
	iex --name a@127.0.0.1 --cookie secret -S mix
b:
	iex --name b@127.0.0.1 --cookie secret -S mix
c:
	iex --name c@127.0.0.1 --cookie secret -S mix
d:
	iex --name d@127.0.0.1 --cookie secret -S mix

# local
lint:
	mix deps.get  & \
	mix deps.compile  & \
	mix format --check-formatted  & \
	mix deps.unlock --check-unused  & \
	mix dialyzer  & \
	mix docs 