.PHONY: add-repo install-default install-operator verify-operator

add-repo:
		helm repo add mongodb https://mongodb.github.io/helm-charts
			helm repo update

install-default:
		helm install enterprise-operator mongodb/enterprise-operator

install-operator:
		helm install enterprise-operator mongodb/enterprise-operator --namespace mongodb-operator --create-namespace

verify-operator:
		kubectl describe deployments mongodb-enterprise-operator -n mongodb-operator

all: add-repo install-operator verify-operator

