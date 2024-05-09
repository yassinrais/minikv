:ok = LocalCluster.start()

Application.ensure_all_started(:minikv)

ExUnit.start()
