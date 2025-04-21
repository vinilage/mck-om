PROJECT_ID ?= 
CLUSTER_NAME ?= 
ZONE ?= 
REGION ?= 
MACHINE_TYPE := n2-standard-2
DISK_TYPE := pd-standard
DISK_SIZE := 100
NUM_NODES := 4
NETWORK := projects/$(PROJECT_ID)/global/networks/default
SUBNETWORK := projects/$(PROJECT_ID)/regions/$(REGION)/subnetworks/default
NODE_LOCATIONS := $(ZONE)
CLUSTER_VERSION := 1.31.6-gke.1064001

.PHONY: create-cluster
.PHONY: connect-cluster

create-cluster:
	@echo "Creating GKE cluster: $(CLUSTER_NAME) in project $(PROJECT_ID)..."
	gcloud beta container --project "$(PROJECT_ID)" clusters create "$(CLUSTER_NAME)" \
		--zone "$(ZONE)" \
		--tier "standard" \
		--no-enable-basic-auth \
		--cluster-version "$(CLUSTER_VERSION)" \
		--release-channel "regular" \
		--machine-type "$(MACHINE_TYPE)" \
		--image-type "COS_CONTAINERD" \
		--disk-type "$(DISK_TYPE)" \
		--disk-size "$(DISK_SIZE)" \
		--metadata disable-legacy-endpoints=true \
		--scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
		--max-pods-per-node "110" \
		--num-nodes "$(NUM_NODES)" \
		--logging=SYSTEM,WORKLOAD \
		--monitoring=SYSTEM,STORAGE,POD,DEPLOYMENT,STATEFULSET,DAEMONSET,HPA,CADVISOR,KUBELET \
		--enable-ip-alias \
		--network "$(NETWORK)" \
		--subnetwork "$(SUBNETWORK)" \
		--no-enable-intra-node-visibility \
		--default-max-pods-per-node "110" \
		--enable-ip-access \
		--security-posture=standard \
		--workload-vulnerability-scanning=disabled \
		--no-enable-google-cloud-access \
		--addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
		--enable-autoupgrade \
		--enable-autorepair \
		--max-surge-upgrade 1 \
		--max-unavailable-upgrade 0 \
		--binauthz-evaluation-mode=DISABLED \
		--enable-managed-prometheus \
		--enable-shielded-nodes \
		--shielded-integrity-monitoring \
		--no-shielded-secure-boot \
		--node-locations "$(NODE_LOCATIONS)"

connect-cluster:
	gcloud container clusters get-credentials $(CLUSTER_NAME) --zone $(ZONE) --project $(PROJECT_ID)





