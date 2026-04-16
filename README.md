# Artifact Evaluation: Correct-by-Design SRE

This repository contains the mechanized proofs, compiler pipeline, and raw telemetry data for the Domain-Specific Engineering Language (DSEL) **Ken-n**, as detailed in the submission *Correct-by-Design SRE: Eliminating Guess-and-Check in Microservices with an Agda-to-Kubernetes Pipeline*.

This artifact allows reviewers to reproduce the core claims of the paper:
1. **Strict $\mathcal{O}(1)$ Verification:** Bypassing state-space explosion by type-checking microservice topologies parametrically.
2. **Zero-Trust Lowering:** Extracting continuous topological invariants into deterministic, default-deny Kubernetes manifests.
3. **Empirical Failure Replication:** Accessing the raw AWS EKS telemetry that physically demonstrates the state-space explosion of traditional CI/CD pipelines.

---

## 📂 Repository Structure

* **/src**: Contains the Agda source files and proof engine.
  * `DSL.agda`: The continuous topological foundation and disjoint union algebra.
  * `Lowering.agda`: The discrete Intermediate Representation (IR) mapping rules.
  * `Test.agda`: The primary evaluation harness containing the frontend-to-database benchmark.
* **/benchmarks**: Contains the pre-compiled output of the test topologies (e.g., `frontend-backend-mesh.yaml`).
* **/results**: Contains the raw AWS EKS telemetry data and logs utilized for Figure 2 and Table 1.
* `Dockerfile`: The hermetic environment definition for artifact evaluation.

---

## 🚀 Part 1: Containerized Evaluation (The Golden Path)

To ensure absolute reproducibility and bypass any local dependency conflicts (GHC/Agda versions), an OCI-compliant container environment (Docker, OrbStack) is highly recommended.

**1. Build the hermetic environment:**
```zsh
docker build -t kenn-artifact .
```

**2. Enter the interactive container:**
```zsh
docker run -it kenn-artifact
```

**3. Type-check and compile the artifact generator:**
```zsh
cd src
# Evaluates the topological safety and compiles the binary
agda --compile Test.agda
```
*(Note: You will observe the $\mathcal{O}(1)$ verification speed during this step as the type-checker resolves the continuous and discrete alignment in sub-second time).*

**4. Generate the Kubernetes manifests:**
```zsh
./Test
```

---

## 🌐 Part 2: Native Evaluation & Simulation

If you prefer to run the formal verification toolchain natively, ensure you have installed:
* Agda (v2.6.4+)
* The Agda Standard Library
* GHC (v9.14.1+)

**1. Type-check the topological bounds natively:**
```zsh
cd src
agda Test.agda
```

**2. Compile and emit the YAML:**
```zsh
agda --compile Test.agda
./Test > generated-mesh.yaml
```

**3. (Optional) Zero-Compute Kubernetes Simulation:**
To prove the emitted manifests are structurally valid without provisioning a physical cluster, we recommend using kwok (Kubernetes WithOut Kubelet) to simulate control-plane resolution.

```zsh
# On your host machine:
brew install kwok kubectl  # macOS/Homebrew
kwokctl create cluster --name kenn-artifact-cluster
kubectl config use-context kwok-kenn-artifact-cluster

# Apply the mathematically verified manifests
kubectl apply -f generated-mesh.yaml
kubectl get pods,networkpolicies
```
Because the manifests are correct-by-design, kwok will instantly resolve the architecture without discrete scheduling latency.

---

## 📊 Part 3: Verifying the Empirical Baseline (Figure 2 / Table 1)

The control group data representing standard "guess-and-check" CI methodologies is provided in the `/results` directory.
Review the telemetry logs here to verify the cascading API server failures and the 121-minute control-plane deadlock triggered by the 250-service mesh, validating the necessity of the Ken-n $\mathcal{O}(1)$ compiler.
