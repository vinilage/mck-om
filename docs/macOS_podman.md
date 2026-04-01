## Use Podman instead of Docker on macOS
You might want to use Podman rather than Docker to more closely mirror a production enviornment or due to licensing constraints. Here's how to configure Podman on macOS so that it will work with K3d (which is recommended for the lab).

### Prerequisites
- Make sure you have homebrew installed
- I've only tested this on an Apple Silicon mac. It should work on Intel macs but I haven't tried it.

```shell
# Install podman
brew install podman

# Create the podman virtual machine
# Using the --rootful flag more closely mirrors Docker
podman machine init --cpus 4 --memory 12288 --rootful
podman machine start

# Install system helper to redirect local tools looking for docker to send requests to podman instead
sudo /opt/homebrew/Cellar/podman/5.8.1/bin/podman-mac-helper install

# Restart podman virtual machine
podman machine stop; podman machine start
```

With podman configured, use k3d just like you would with Docker!

