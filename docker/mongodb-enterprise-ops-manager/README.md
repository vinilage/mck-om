### Building locally

For building the MongoDB Enterprise Ops Manager Docker image locally use the example command:

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