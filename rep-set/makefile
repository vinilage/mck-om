.PHONY: deploy-rs

deploy-rs:
	kubectl apply -f secret.yaml
	kubectl apply -f config-map.yaml
	kubectl apply -f replica-set.yaml

