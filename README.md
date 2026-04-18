# Ken-n: Artifact Evaluation

This repository contains the mechanized proofs, compiler pipeline, and raw telemetry data for the Domain-Specific Engineering Language (DSEL) **Ken-n**. 

This artifact supports two distinct, double-blind submissions:
1. **The PLT Track (POPL/ICFP):** Focuses on the univalent mechanization, denotational semantics, and $\mathcal{O}(1)$ parametric proof erasure in Cubical Agda.
2. **The Systems Track (NSDI/OSDI):** Focuses on the discrete infrastructure translation ($\mathcal{L}$ functor), zero-trust NetworkPolicy generation, and the Kubernetes control-plane deadlock benchmarks.

## 🚀 Getting Started (Kick-the-Tires)

To ensure strict reproducibility and avoid host-OS dependency conflicts (specifically regarding Haskell, GHC, and Cubical Agda), this artifact is fully containerized.

**Prerequisites:**
* Docker (v20+)
* Make

**1. Build the Hermetic Environment:**
```bash
git clone [https://github.com/sre-researcher-anon/kenn-artifact-evaluation.git](https://github.com/sre-researcher-anon/kenn-artifact-evaluation.git)
cd kenn-artifact-evaluation
make docker-build
```

**2. Enter the Sandbox:**
```bash
make docker-shell
```
*Note: All subsequent commands should be run inside this container.*

---

## 📁 Repository Structure

```text
├── agda-src/                # Cubical Agda source for the Ken-n algebra
│   ├── Topology.agda        # Axioms of Open Sets, Unions, and Intersections
│   └── Deployments.agda     # Continuous Homotopy and Routing Equivalences
├── compiler/                # The L lowering functor (Haskell)
│   ├── Main.hs              # AST Traversal and Proof Erasure
│   └── Emitter.hs           # Generates the JSON IR and K8s YAML
├── benchmarks/              # Scripts to reproduce paper tables/figures
│   ├── plt-scaling.sh       # O(1) compilation benchmarks
│   ├── latency-wrk2.sh      # Istio vs. Ken-n CNI performance tests
│   └── manifests/           # Extracted K8s YAML for the 250-service mesh
└── telemetry/               # Raw AWS EKS logs from the staging deadlocks
```

---

## 🧪 Track A: PLT Evaluation (POPL / ICFP)

**Supported Claims:** The Ken-n type-checker evaluates horizontal scaling parametrically, bypassing state-space explosion and resulting in a strictly $\mathcal{O}(1)$ compilation time regardless of cluster size (Table 1 in the PLT manuscript).

### Reproducing the $\mathcal{O}(1)$ Scaling Benchmark
Run the PLT benchmark script, which invokes the Agda engine on topologies of increasing autoscaler cardinality (N=10, 1000, and 10000):

```bash
make eval-plt-scaling
```

**Expected Output:**
The script will output the exact GHC compilation times for each index set. You should observe that the compilation time remains flat (within a ~0.1s margin of error due to JIT caching), matching the ~1.14s claim in the paper.

---

## ⚙️ Track B: Systems Evaluation (NSDI / OSDI)

**Supported Claims:** 1. Empirical staging of complex meshes (250 services / 840 intersections) causes exponential state-space explosion and control-plane deadlocks, while Ken-n compiles the IR in under 1 second (Table 1 & Figure 1 in the Systems manuscript).
2. Compile-time verified CNI policies outperform runtime Envoy sidecars (Istio) by eliminating user-space packet interception (Table 2 in the Systems manuscript).

### 1. Reproducing the Control-Plane Deadlock (Figure 1 & Table 1)
Because reproducing a full control-plane deadlock requires provisioning 500 physical `m5.large` EC2 instances, we provide two methods of evaluation:

**Method A: Fast Local Simulation (kwok)**
We utilize `kwok` (Kubernetes WithOut Kubelet) to simulate the control-plane resolution of the 250-service mesh without requiring physical cloud compute.
```bash
make eval-sys-compilation
```
*Expected Output:* The Ken-n compiler will generate the JSON IR and native YAML in < 1 second. The script will then pipe the YAML into the simulated cluster, demonstrating API resolution without physical node latency.

**Method B: Raw AWS EKS Telemetry**
The raw cluster event logs demonstrating the 121-minute deadlock (Figure 1) are available in `telemetry/eks-deadlock-raw.log`. 

### 2. Reproducing the Latency Benchmarks (Table 2)
To prove the performance gains of removing Istio sidecars in favor of Ken-n's mathematically generated CNI policies, run the localized `wrk2` load test:

```bash
make eval-sys-latency
```
*Expected Output:* The script spins up two temporary `kind` clusters (one permissive + Istio, one strict Ken-n CNI) and executes a 10,000 RPS burst. The output will display the P50 and P99 tail latencies, confirming the ~3x penalty introduced by the runtime sidecar.

---

## 🛠️ Extending Ken-n (Interactive Compilation)

To see the lowering functor (L) in action, you can author a custom deployment topology.

1. Open `agda-src/Demo.agda`.
2. Define a new `Manifest` using the mixfix DSL.
3. Run the compiler manually:
```bash
kenn-compile agda-src/Demo.agda --out-dir ./output
```
Inspect the `./output/ir.json` to see the erased invariants, and `./output/manifests.yaml` to see the discrete infrastructure generated from your topological proofs.
