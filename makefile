.PHONY: deploy

deploy:
	kubectl apply -f secret.yaml
	kubectl apply -f config-map.yaml
	kubectl apply -f replica-set.yaml

