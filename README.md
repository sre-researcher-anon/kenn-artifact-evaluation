# Ken-n: Artifact Evaluation

Welcome to the artifact evaluation repository for **Ken-n**. This repository contains the mechanized proofs, the compiler pipeline, and the raw telemetry data for the Domain-Specific Engineering Language (DSEL) **Ken-n**.

This artifact supports two distinct, double-blind submissions:
1. **Track A (PLT):** Focuses on the univalent mechanization, denotational semantics, and the $\mathcal{O}(1)$ parametric proof erasure in Cubical Agda.
2. **Track B (Systems - NSDI):** Focuses on the discrete infrastructure translation ($\mathcal{L}$ functor), zero-trust NetworkPolicy generation, and the empirical Kubernetes control-plane deadlock benchmarks.

---

## 🏗️ Artifact Architecture: The Compile-Time / Run-Time Split

To rigorously evaluate the Ken-n calculus, this artifact separates **theoretical verification** from **physical execution**. The evaluation is divided into two distinct environments:

### 1. The Hermetic Compile-Time Environment (Docker)
The Agda univalent engine is housed inside a strictly hermetic Debian Docker container.
* **Why:** This isolates the compiler from host OS discrepancies and proves that our $\mathcal{O}(1)$ parametric scaling and $\mathcal{O}(V + E)$ topological intersection proofs hold mathematically.
* **What runs here:** `plt-scaling.sh`, deadlock compilation proofs, the Haskell lowering functor, and telemetry log parsing.

### 2. The Physical Run-Time Environment (Host Machine)
The latency overhead benchmarks measure physical network packet traversal (CNI vs. Envoy).
* **Why:** You cannot measure true RPC latency or eBPF routing inside an isolated container. These scripts run on your host machine to interact with your physical/local Kubernetes cluster.
* **What runs here:** `latency-wrk2.sh` and physical cluster deployments.

---

## 🚀 Getting Started (Environment Setup)

### Hardware Requirements
Before building the container, please ensure your Docker daemon is allocated sufficient resources:
* **RAM:** 8GB minimum.
* **Architecture:** Tested on x86_64 and ARM64.

**1. Clone the anonymous repository:**
```bash
git clone [https://github.com/sre-researcher-anon/kenn-artifact-evaluation.git](https://github.com/sre-researcher-anon/kenn-artifact-evaluation.git)
cd kenn-artifact-evaluation
```

**2. Build and enter the hermetic Docker environment:**
```bash
docker build -t kenn-artifact-env .
docker run -it kenn-artifact-env /bin/bash
```

> *Note: Unless otherwise specified, all subsequent evaluation commands should be run inside this interactive container shell.*

---

## 📁 Repository Structure

```text
kenn-artifact-evaluation/
├── Dockerfile
├── README.md
├── agda-output/                 # The JSON Trust Boundary
│   ├── checkout-verified.json
│   └── deathstar-verified.json
├── agda-src/                    # The Continuous Topology (Cubical Agda)
│   ├── Kenn/
│   │   ├── DSL.agda             # Mixfix operators and manifest smart constructors
│   │   └── Topology/
│   │       ├── Core.agda        # Open Sets, Disjoint Unions, Intersections
│   │       ├── Homotopy.agda    # Univalent Deployments
│   │       └── State.agda       # Closed Sets and Hash Rings
│   └── DeathStarBench/
│       └── SocialNetwork.agda   # The 362 LoC ported mesh
├── compiler/                    # The Discrete Translation (Haskell)
│   ├── Main.hs                  # Reflection parser and JSON ingest
│   └── Lowering.hs              # The L functor generating K8s YAML/eBPF
├── benchmarks/                  # Execution Scripts for Reviewers
│   ├── plt-scaling.sh           # O(1) Parametric scaling test
│   ├── latency-wrk2.sh          # Native CNI vs. Envoy sidecar test
│   └── manifests/               # Extracted K8s YAML for the benchmarks
└── telemetry/                   # The Hard Physical Data
    ├── eks-deadlock-raw.log     # The 121-minute control-plane crash dump
    ├── latency-results.log      # Output from the wrk2 load tests
    └── parse_deadlock_metrics.py# Parser for the Kubernetes event stream
```

---

## 🧪 Track A: PLT Evaluation

**Supported Claim:** The Ken-n type-checker evaluates horizontal scaling parametrically, bypassing state-space explosion and resulting in a strictly $\mathcal{O}(1)$ compilation time regardless of cluster size.

### Reproducing the Scaling Benchmark
Run the provided benchmark script, which invokes the Cubical Agda engine on topologies of increasing autoscaler cardinality.
```bash
./benchmarks/plt-scaling.sh
```
*Expected Output:* The script will output the exact GHC compilation times for each index set (10, 1000, and 10000 replicas). You will observe that the compilation time remains flat across all scales, confirming the ~1.21s execution claim established in the paper.

---

## ⚙️ Track B: Systems Evaluation (NSDI)

**1. Reproducing the DeathStarBench Compilation**
To verify the sub-second compilation of the highly entangled DeathStarBench Social Network topology:
```bash
time agda --cubical agda-src/DeathStarBench/SocialNetwork.agda
```
*Expected Output:* The compiler will evaluate the network intersections and output a univalent collapse error (circular dependency detected) in ~0.784 seconds, structurally preventing the topology from compiling.

**2. Reproducing the Lowering Functor ($\mathcal{L}$)**
To verify the Haskell compiler's ability to ingest mathematical IR and deterministically generate zero-trust policies:
```bash
cd compiler
runhaskell Main.hs ../agda-output/deathstar-verified.json
```
*Expected Output:* The compiler will parse the JSON AST and output discrete Kubernetes `Deployment` and `NetworkPolicy` YAML.

**3. Control-Plane Deadlock Telemetry**
Physical cluster crashes are cost-prohibitive for local artifact review. We provide the raw telemetry logs extracted directly from our AWS EKS cluster during the 250-service deadlock experiment. We include a Python parsing script that filters the massive Kubernetes event stream to clearly highlight the cascading failures.
```bash
python3 telemetry/parse_deadlock_metrics.py --log-file telemetry/eks-deadlock-raw.log
```
*Expected Output:* The parser will output the chronological degradation of the API server (IPAM exhaustion, OOM evictions, Control Plane Deadlock), strictly verifying the 121-minute timeline cited in the NSDI manuscript.

**4. RPC Latency Benchmarks (Host Machine)**
To prove the performance gains of removing Istio sidecars in favor of Ken-n's mathematically generated native CNI policies, exit the Docker container and run the localized `wrk2` load test against your local cluster.
```bash
# Run this on your host machine
./benchmarks/latency-wrk2.sh
```
*Expected Output:* The output will display the P50 and P99 tail latencies for both configurations, validating the metrics presented in the manuscript.
