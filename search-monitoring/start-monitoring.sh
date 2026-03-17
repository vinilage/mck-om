#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

NAMESPACE="${K8S_NAMESPACE:-mongodb-operator}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-12345678}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-600s}"
KEEP_PORT_FORWARDS="${KEEP_PORT_FORWARDS:-true}"

PORT_FORWARD_PIDS=()

cleanup() {
  if [ "${#PORT_FORWARD_PIDS[@]}" -gt 0 ]; then
    echo ""
    echo "Stopping background port-forwards..."
    for pid in "${PORT_FORWARD_PIDS[@]}"; do
      if kill -0 "$pid" >/dev/null 2>&1; then
        kill "$pid" >/dev/null 2>&1 || true
      fi
    done
  fi
}

handle_interrupt() {
  echo ""
  echo "Interrupted; stopping background port-forwards..."
  cleanup
  exit 130
}

if [[ "$KEEP_PORT_FORWARDS" == "false" ]]; then
  trap cleanup EXIT
else
  trap handle_interrupt INT TERM
fi

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "❌ Required command not found: $command_name"
    exit 1
  fi
}

confirm_kube_context() {
  local current_context
  local current_cluster
  local current_user

  current_context="$(kubectl config current-context 2>/dev/null || true)"
  if [[ -z "$current_context" ]]; then
    echo "❌ No active kubectl context found."
    echo "Set one first with: kubectl config use-context <context-name>"
    exit 1
  fi

  current_cluster="$(kubectl config view -o jsonpath="{.contexts[?(@.name=='$current_context')].context.cluster}" 2>/dev/null || true)"
  current_user="$(kubectl config view -o jsonpath="{.contexts[?(@.name=='$current_context')].context.user}" 2>/dev/null || true)"

  echo ""
  echo "🔎 Kubernetes context check"
  echo "  Context:   $current_context"
  echo "  Cluster:   ${current_cluster:-unknown}"
  echo "  User:      ${current_user:-unknown}"
  echo "  Namespace: $NAMESPACE"
  echo ""

  read -r -p "Proceed with this Kubernetes context? (y/N): " CONTEXT_REPLY
  if [[ ! "$CONTEXT_REPLY" =~ ^[Yy]$ ]]; then
    echo "Aborted by user."
    exit 0
  fi
}

wait_for_http() {
  local url="$1"
  local timeout_seconds="${2:-60}"

  for _ in $(seq 1 "$timeout_seconds"); do
    if curl -s -f "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  return 1
}

wait_for_prometheus_job_up() {
  local job_name="$1"
  local timeout_seconds="${2:-120}"

  for _ in $(seq 1 "$timeout_seconds"); do
    if curl -s -G "http://localhost:9090/api/v1/query" --data-urlencode "query=up{job=\"$job_name\"}" \
      | jq -e '.status == "success" and (.data.result | length > 0) and ([.data.result[].value[1] | tonumber] | any(. >= 1))' >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  return 1
}

ensure_endpoint() {
  local url="$1"
  local name="$2"
  local resource="$3"
  local local_port="$4"
  local target_port="$5"

  if curl -s -f "$url" >/dev/null 2>&1; then
    echo "✅ $name already reachable at $url"
    return 0
  fi

  local log_file
  log_file="$(mktemp)"

  echo "ℹ️  Starting port-forward for $name ($resource $local_port:$target_port)..."
  kubectl port-forward -n "$NAMESPACE" "$resource" "$local_port:$target_port" >"$log_file" 2>&1 &
  local pf_pid=$!
  PORT_FORWARD_PIDS+=("$pf_pid")

  if wait_for_http "$url" 60; then
    echo "✅ $name reachable at $url"
    return 0
  fi

  echo "❌ Failed to expose $name at $url"
  echo "Port-forward logs:"
  cat "$log_file"
  exit 1
}


echo "Starting Search monitoring on Kubernetes..."

echo "Using namespace: $NAMESPACE"
echo "Using passwords:"
echo "  MongoDB Admin: [HIDDEN]"
echo "  Grafana Admin: [HIDDEN]"

require_command kubectl
require_command curl
require_command jq

confirm_kube_context

if [ ! -f "$SCRIPT_DIR/kustomization.yaml" ]; then
  echo "❌ kustomization.yaml not found in $SCRIPT_DIR."
  exit 1
fi

echo ""
echo "Applying Kubernetes manifests..."
kubectl apply -k "$SCRIPT_DIR"

echo ""
echo "Waiting for MongoDBSearch to be ready..."
if ! kubectl wait -n "$NAMESPACE" mongodbsearch/replica-set \
  --for=jsonpath='{.status.phase}'=Running \
  --timeout="$WAIT_TIMEOUT" 2>/dev/null; then
  echo "⚠️  Warning: MongoDBSearch status check timed out or not available"
fi

echo "Waiting for Search StatefulSet to be ready..."
if kubectl get statefulset replica-set-search -n "$NAMESPACE" >/dev/null 2>&1; then
  kubectl rollout status statefulset/replica-set-search -n "$NAMESPACE" --timeout="$WAIT_TIMEOUT"
else
  echo "⚠️  Warning: Search StatefulSet not found, checking service directly..."
fi

echo "Verifying service port is available..."
until kubectl get svc replica-set-search-svc -n "$NAMESPACE" -o jsonpath='{.spec.ports[?(@.port==9946)].port}' 2>/dev/null | grep -q 9946; do
  echo "  Waiting for port 9946 to be exposed on replica-set-search-svc..."
  sleep 2
done
echo "✅ Service port 9946 is available"

echo ""
echo "Waiting for core monitoring deployments..."
kubectl rollout status -n "$NAMESPACE" deployment/prometheus --timeout="$WAIT_TIMEOUT"
kubectl rollout status -n "$NAMESPACE" deployment/grafana --timeout="$WAIT_TIMEOUT"

echo "Reloading Prometheus to ensure latest scrape configuration is active..."
kubectl rollout restart -n "$NAMESPACE" deployment/prometheus
kubectl rollout status -n "$NAMESPACE" deployment/prometheus --timeout="$WAIT_TIMEOUT"

echo ""
echo "Preparing local access to endpoints..."
ensure_endpoint "http://localhost:9946/metrics" "MongoDB Search Metrics" "svc/replica-set-search-svc" 9946 9946
ensure_endpoint "http://localhost:9090" "Prometheus" "svc/prometheus" 9090 9090
ensure_endpoint "http://localhost:3000" "Grafana" "svc/grafana" 3000 3000

echo ""
echo "Waiting for Prometheus scrape targets to report UP..."
if ! wait_for_prometheus_job_up "mongot" 120; then
  echo "❌ Prometheus target 'mongot' did not become UP in time."
  exit 1
fi
echo "✅ Prometheus scrape targets are UP"

echo ""
echo "Services available at:"
echo "  Search Metrics:     http://localhost:9946/metrics"
echo "  Prometheus:         http://localhost:9090"
echo "  Grafana:            http://localhost:3000 (admin/${GRAFANA_PASSWORD})"


echo ""
echo "🧪 Running Kubernetes monitoring tests..."
if [ -x "./test-monitoring.sh" ]; then
  "./test-monitoring.sh"
else
  echo "⚠️  test-monitoring.sh not found or not executable"
  echo "   Run 'chmod +x test-monitoring.sh'"
fi

echo ""
echo "🧪 Running dashboard metrics test (no-data mode)..."
if [ -x "./test-dashboard-metrics.sh" ]; then
  (
    ./test-dashboard-metrics.sh
  )
else
  echo "⚠️  test-dashboard-metrics.sh not found or not executable"
  echo "   Run 'chmod +x test-dashboard-metrics.sh'"
fi

echo ""
echo "📊 Setup complete! You can now:"
echo "  1. View metrics in Prometheus at http://localhost:9090"
echo "  2. Open Grafana at http://localhost:3000"
if [[ "$KEEP_PORT_FORWARDS" == "true" ]]; then
  echo "  3. Stop local port-forwards later with ./stop-monitoring-k8s.sh"
fi

echo ""
echo "🎯 Would you like to generate test metrics now?"
read -r -p "Generate test metrics? (y/N): " REPLY

if [[ "$REPLY" =~ ^[Yy]$ ]]; then
  echo ""
  echo "🚀 Running local metric generation script..."
  if [ -x "./generate-metrics.sh" ]; then
    K8S_NAMESPACE="$NAMESPACE" ADMIN_PASSWORD="$ADMIN_PASSWORD" "./generate-metrics.sh" k8s
  else
    echo "⚠️  generate-metrics.sh not found or not executable"
    echo "   Run 'chmod +x generate-metrics.sh'"
    exit 1
  fi

  echo ""
  echo "🧪 Running strict dashboard metrics test after data generation..."
  if [ -x "./test-dashboard-metrics.sh" ]; then
    (
      ./test-dashboard-metrics.sh --strict
    )
  else
    echo "⚠️  test-dashboard-metrics.sh not found or not executable"
    echo "   Run 'chmod +x test-dashboard-metrics.sh'"
  fi
else
  echo ""
  echo "💡 To generate metrics later, run:"
  echo "   K8S_NAMESPACE=$NAMESPACE ./generate-metrics.sh k8s"
fi

echo ""
echo "Done."
