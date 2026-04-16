{-# OPTIONS --guardedness #-}
module Kenn.Test where

open import Kenn.DSL
open import Kenn.Compiler.Lowering
open import Data.String using (String)
open import IO using (Main; run; putStrLn)

-- Postulate the continuous proofs for the artifact generation
postulate
  dummy-math : Σ → Set

-- Define the Nodes
web-ui : Microservice
web-ui = open-set "frontend" "nginx:latest" 80 dummy-math dummy-math

database : Microservice
database = open-set "backend" "postgres:15" 5432 dummy-math dummy-math

-- The Topology: UI routes strictly to Database
production-mesh : Mesh
production-mesh = node web-ui ▹ node database

-- The Pipeline
output-yaml : String
output-yaml = K8sManifest.yaml (compile-to-k8s (evaluate-to-IR production-mesh))

-- The Entry Point
main : Main
main = run (putStrLn output-yaml)
