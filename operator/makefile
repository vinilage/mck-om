.PHONY: add-repo install-default install-operator verify-operator install-mck

add-repo:
	helm repo add mongodb https://mongodb.github.io/helm-charts
	helm repo update

install-default:
	helm install kubernetes-operator mongodb/mongodb-kubernetes

install-operator:
	helm install kubernetes-operator mongodb/mongodb-kubernetes --namespace mongodb-operator --create-namespace

verify-operator:
	kubectl describe deployments mongodb-kubernetes-operator -n mongodb-operator

install-mck: add-repo install-operator verify-operator
