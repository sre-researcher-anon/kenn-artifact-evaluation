#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure wrk2 is installed
if ! command -v wrk &> /dev/null; then
    echo -e "${RED}Error: wrk2 is not installed. Please install it to run this benchmark.${NC}"
    exit 1
fi

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE} Ken-n: Systems Evaluation - CNI vs. Envoy Sidecar    ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Function to run wrk2 and extract P50/P99 latencies
run_benchmark() {
    local config_name=$1
    local target_url=$2
    
    echo "Warming up $config_name endpoint..."
    # 5-second warmup
    wrk -t2 -c100 -d5s -R10000 "$target_url" > /dev/null 2>&1
    
    echo "Running 30-second benchmark for $config_name at 10,000 RPS..."
    # Run the actual benchmark and capture output
    local wrk_output=$(wrk -t2 -c100 -d30s -R10000 --latency "$target_url")
    
    # Parse the text output using awk to grab the 50% and 99% lines
    local p50=$(echo "$wrk_output" | awk '$1 == "50.000%" {print $2}')
    local p99=$(echo "$wrk_output" | awk '$1 == "99.000%" {print $2}')
    
    # If awk fails to parse (e.g., connection refused), default to ERR
    p50=${p50:-"ERR"}
    p99=${p99:-"ERR"}

    echo "$p50|$p99"
}

printf "\n%-30s %-15s %-15s\n" "Enforcement Strategy" "P50 Latency" "P99 Latency"
echo "------------------------------------------------------------------"

# ==========================================
# 1. BASELINE (Permissive)
# ==========================================
kubectl apply -f ./manifests/baseline-permissive.yaml > /dev/null
kubectl rollout status deployment/checkout-baseline --timeout=60s > /dev/null
# Assuming local port-forwarding is handled or running via ClusterIP
baseline_res=$(run_benchmark "Baseline" "http://localhost:8080/checkout")
baseline_p50=$(echo $baseline_res | cut -d'|' -f1)
baseline_p99=$(echo $baseline_res | cut -d'|' -f2)
printf "%-30s %-15s %-15s\n" "Baseline (Permissive)" "$baseline_p50" "$baseline_p99"


# ==========================================
# 2. KEN-N ZERO TRUST (Native CNI)
# ==========================================
kubectl apply -f ./manifests/kenn-zero-trust.yaml > /dev/null
kubectl rollout status deployment/checkout-kenn --timeout=60s > /dev/null
kenn_res=$(run_benchmark "Ken-n CNI" "http://localhost:8081/checkout")
kenn_p50=$(echo $kenn_res | cut -d'|' -f1)
kenn_p99=$(echo $kenn_res | cut -d'|' -f2)
printf "${GREEN}%-30s %-15s %-15s${NC}\n" "Ken-n Compiled (Native CNI)" "$kenn_p50" "$kenn_p99"


# ==========================================
# 3. ISTIO (Envoy Sidecar)
# ==========================================
# Label namespace for Istio injection
kubectl label namespace default istio-injection=enabled --overwrite > /dev/null
kubectl apply -f ./manifests/istio-mesh.yaml > /dev/null
kubectl rollout status deployment/checkout-istio --timeout=90s > /dev/null
istio_res=$(run_benchmark "Istio Sidecar" "http://localhost:8082/checkout")
istio_p50=$(echo $istio_res | cut -d'|' -f1)
istio_p99=$(echo $istio_res | cut -d'|' -f2)
printf "${RED}%-30s %-15s %-15s${NC}\n" "Istio (Envoy Sidecar)" "$istio_p50" "$istio_p99"

# Cleanup
kubectl label namespace default istio-injection- > /dev/null

echo -e "\n${GREEN}✔ Systems Evaluation Complete.${NC}"
