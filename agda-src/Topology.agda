module Kenn.DSL where

open import Level using (Level; _⊔_; 0ℓ)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; trans)
open import Data.Product using (_×_; _,_)
open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥)
open import Data.String using (String)
open import Data.Nat using (ℕ)

------------------------------------------------------------------------
-- 1. The Topological Foundation (Continuous Semantics)
------------------------------------------------------------------------
postulate
  Σ : Set

record Microservice : Set₁ where
  constructor open-set
  field
    -- Discrete Metadata
    id    : String
    image : String
    port  : ℕ
    
    -- Continuous Semantics (Internal State Space Limits)
    ⟦_⟧    : Σ → Set
    isOpen : Σ → Set 

------------------------------------------------------------------------
-- 2. The Abstract Syntax of the DSEL (Categorical Topology)
------------------------------------------------------------------------
data Mesh : Set₁ where
  ∅     : Mesh                              -- Identity: Null deployment
  node  : Microservice → Mesh               -- Single isolated service
  _⊕_   : Mesh → Mesh → Mesh                -- Disjoint Union: Zero-trust isolation
  _▹_   : Mesh → Mesh → Mesh                -- Morphism: Directed continuous map (Routing)

------------------------------------------------------------------------
-- 3. The Monoid Laws (For the Disjoint Union)
------------------------------------------------------------------------
record IsMeshMonoid : Set₂ where
  field
    assoc : (A B C : Mesh) → (A ⊕ B) ⊕ C ≡ A ⊕ (B ⊕ C)
    idL   : (A : Mesh) → ∅ ⊕ A ≡ A
    idR   : (A : Mesh) → A ⊕ ∅ ≡ A
