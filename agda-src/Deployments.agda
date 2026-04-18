module Kenn.Compiler.Lowering where

open import Kenn.DSL
open import Data.String using (String)
open import Data.List using (List; []; _∷_; _++_)
open import Data.Nat using (ℕ)

------------------------------------------------------------------------
-- Phase 1: The Discrete State Space (Intermediate Representation)
------------------------------------------------------------------------
ServiceID : Set
ServiceID = String

record Node : Set where
  constructor mkNode
  field
    id    : ServiceID
    image : String
    port  : ℕ

record Edge : Set where
  constructor mkEdge
  field
    src  : ServiceID
    dest : ServiceID
    port : ℕ

record GraphIR : Set where
  constructor mkGraph
  field
    nodes : List Node
    edges : List Edge

------------------------------------------------------------------------
-- Phase 2: First Lowering (Continuous Truth -> Discrete IR)
------------------------------------------------------------------------

-- Helper: Merge two disjoint graphs
union-IR : GraphIR → GraphIR → GraphIR
union-IR (mkGraph n1 e1) (mkGraph n2 e2) = 
  mkGraph (n1 ++ n2) (e1 ++ e2)

-- Helper: Draw exact edges from one source to a list of destinations
build-edges : Node → List Node → List Edge
build-edges src [] = []
build-edges src (dest ∷ dests) = 
  mkEdge (Node.id src) (Node.id dest) (Node.port dest) ∷ build-edges src dests

-- Helper: Draw exact edges from a frontier of sources to destinations
connect-graphs : List Node → List Node → List Edge
connect-graphs [] _ = []
connect-graphs (src ∷ srcs) dests = 
  build-edges src dests ++ connect-graphs srcs dests

-- The Inductive Lowering Algorithm
evaluate-to-IR : Mesh → GraphIR
evaluate-to-IR ∅ = 
  mkGraph [] []

evaluate-to-IR (node m) = 
  let n = mkNode (Microservice.id m) (Microservice.image m) (Microservice.port m)
  in mkGraph (n ∷ []) []

evaluate-to-IR (A ⊕ B) = 
  -- Disjoint union: strictly parallel, zero edges generated
  union-IR (evaluate-to-IR A) (evaluate-to-IR B)

evaluate-to-IR (A ▹ B) = 
  -- Morphism: compute graphs, merge, and generate explicit unidirectional routing
  let graphA = evaluate-to-IR A
      graphB = evaluate-to-IR B
      newEdges = connect-graphs (GraphIR.nodes graphA) (GraphIR.nodes graphB)
      merged = union-IR graphA graphB
  in mkGraph (GraphIR.nodes merged) (GraphIR.edges merged ++ newEdges)

------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
-- Phase 3: Second Lowering (Discrete IR -> Kubernetes Pipeline)
------------------------------------------------------------------------
open import Data.String hiding (show) renaming (_++_ to _++str_)
open import Data.Nat.Show using (show)

record K8sManifest : Set where
  constructor mkManifest
  field
    yaml : String

-- 1. Lower Nodes into Deployments and Services
lower-node : Node → String
lower-node (mkNode id img port) = 
  "---\n" ++str
  "apiVersion: apps/v1\nkind: Deployment\n" ++str
  "metadata:\n  name: " ++str id ++str "\n" ++str
  "spec:\n  selector:\n    matchLabels:\n      app: " ++str id ++str "\n" ++str
  "  template:\n    metadata:\n      labels:\n        app: " ++str id ++str "\n" ++str
  "    spec:\n      containers:\n      - name: " ++str id ++str "\n        image: " ++str img ++str "\n" ++str
  "        ports:\n        - containerPort: " ++str show port ++str "\n" ++str
  "---\n" ++str
  "apiVersion: v1\nkind: Service\n" ++str
  "metadata:\n  name: " ++str id ++str "\n" ++str
  "spec:\n  selector:\n    app: " ++str id ++str "\n" ++str
  "  ports:\n    - port: " ++str show port ++str "\n"

lower-nodes : List Node → String
lower-nodes [] = ""
lower-nodes (n ∷ ns) = lower-node n ++str lower-nodes ns

-- 2. Lower Edges into Zero-Trust NetworkPolicies
default-deny : String
default-deny = 
  "---\n" ++str
  "apiVersion: networking.k8s.io/v1\nkind: NetworkPolicy\n" ++str
  "metadata:\n  name: default-deny-all\n" ++str
  "spec:\n  podSelector: {}\n  policyTypes:\n  - Ingress\n  - Egress\n"

lower-edge : Edge → String
lower-edge (mkEdge src dest port) = 
  "---\n" ++str
  "apiVersion: networking.k8s.io/v1\nkind: NetworkPolicy\n" ++str
  "metadata:\n  name: allow-" ++str src ++str "-to-" ++str dest ++str "\n" ++str
  "spec:\n  podSelector:\n    matchLabels:\n      app: " ++str dest ++str "\n" ++str
  "  policyTypes:\n  - Ingress\n" ++str
  "  ingress:\n  - from:\n    - podSelector:\n        matchLabels:\n          app: " ++str src ++str "\n" ++str
  "    ports:\n    - protocol: TCP\n      port: " ++str show port ++str "\n"

lower-edges : List Edge → String
lower-edges [] = ""
lower-edges (e ∷ es) = lower-edge e ++str lower-edges es

-- The Final Compiler Output
compile-to-k8s : GraphIR → K8sManifest
compile-to-k8s (mkGraph ns es) = 
  mkManifest (lower-nodes ns ++str default-deny ++str lower-edges es)
