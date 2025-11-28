## Generate ARM compatible image of Ops Manager - WiP

Work in progress...

OpsManager is a Java application, which means that it is portable to different architectures by using the proper JDK.  
At the time of writing this doc, OpsManager has no official support for ARM architecture, which means that you cannot find an official arm package in the [download center](https://www.mongodb.com/try/download/ops-manager) as well as you will not find an official arm image in our [Quay](https://quay.io/repository/mongodb/mongodb-enterprise-ops-manager-ubi?tab=tags&tag=latest) registries. Because of this, the arm image of OpsManager will be built locally, and we will need to configure the Kubernetes Operator to use this local image. This is possible, since the operator offers support of [static-architecture](https://www.mongodb.com/docs/kubernetes/current/tutorial/plan-k8s-op-container-images/).

### Building ARM OM image locally

For building Ops Manager 8.0.7 Docker image locally use the following command.  
If you need to change the version, you will need to update the download [links](https://github.com/karl-denby/mongo-infra-docker/blob/main/ops-manager/quick-start.sh) as well.

```bash
VERSION="8.0.7"
OM_DOWNLOAD_URL="https://downloads.mongodb.com/on-prem-mms/tar/mongodb-mms-8.0.7.500.20250505T1426Z.tar.gz"
JDK_ARM_DOWNLOAD_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.6%2B7/OpenJDK21U-jdk_aarch64_linux_hotspot_21.0.6_7.tar.gz" 
docker buildx build --load --progress plain . \
  -f docker/mongodb-enterprise-ops-manager/Dockerfile \
  -t "mongodb-enterprise-ops-manager:${VERSION}" \
  --build-arg version="${VERSION}" \
  --build-arg om_download_url="${OM_DOWNLOAD_URL}" \
  --build-arg jdk_arm_download_url="${JDK_ARM_DOWNLOAD_URL}"
```