
.PHONY: create-kind-cluster
.PHONY: create-k3d-cluster
.PHONY: clean-up

create-kind-cluster:
	@echo "Creating local Kind cluster: mongodb-mck-cluster..."
	kind create cluster --name mongodb-mck-cluster
	@echo "Setting the kubectl context to mongodb-mck-cluster..."
	kubectl config use-context kind-mongodb-mck-cluster

create-k3d-cluster:
	@echo "Creating local k3d cluster: mongodb-mck-cluster..."
	k3d cluster create mongodb-mck-cluster

clean-up:
	@echo "Deleting 'kind-mongodb-mck-cluster' cluster..."
	kind delete cluster --name mongodb-mck-cluster

	@echo "Removing the operator 'kind-mongodb-mck-cluster' cluster..."
	helm uninstall kubernetes-operator --namespace mongodb-operator

	@echo "Cleaning up the 'mongodb-operator' namespace..."
	kubectl delete namespace mongodb-operator --ignore-not-found
