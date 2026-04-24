{-# OPTIONS --cubical #-}
module Kenn.DSL where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.Univalence
open import Cubical.Data.Sum as Sum
open import Cubical.Data.Empty as Empty
open import Cubical.Data.Nat
open import Cubical.Data.Sigma 
open import Agda.Builtin.String using (String)

------------------------------------------------------------------------
-- 1. The Topological Foundation (Continuous Semantics)
------------------------------------------------------------------------
postulate
  Space : Type₀

record Microservice : Type₁ where
  constructor open-set
  field
    id    : String
    image : String
    port  : ℕ
    neighborhood : Space → Type₀

------------------------------------------------------------------------
-- 2. The Abstract Syntax of the DSEL (Categorical Topology)
------------------------------------------------------------------------
data Mesh : Type₁ where
  ∅     : Mesh                                
  node  : Microservice → Mesh                 
  _⊕_   : Mesh → Mesh → Mesh                  
  _▹_   : Mesh → Mesh → Mesh                  

------------------------------------------------------------------------
-- 3. Univalent Proofs: Structural Isolation via Disjoint Union
------------------------------------------------------------------------
⟦_⟧ : Mesh → Space → Type₀
⟦ ∅ ⟧ x = ⊥
⟦ node m ⟧ x = Microservice.neighborhood m x
⟦ A ⊕ B ⟧ x = ⟦ A ⟧ x ⊎ ⟦ B ⟧ x
⟦ A ▹ B ⟧ x = ⟦ A ⟧ x × ⟦ B ⟧ x  

⊕-comm-iso : ∀ {A B : Mesh} {x : Space} → Iso (⟦ A ⊕ B ⟧ x) (⟦ B ⊕ A ⟧ x)
Iso.fun ⊕-comm-iso (inl a) = inr a
Iso.fun ⊕-comm-iso (inr b) = inl b
Iso.inv ⊕-comm-iso (inl b) = inr b
Iso.inv ⊕-comm-iso (inr a) = inl a
Iso.rightInv ⊕-comm-iso (inl b) = refl
Iso.rightInv ⊕-comm-iso (inr a) = refl
Iso.leftInv ⊕-comm-iso (inl a) = refl
Iso.leftInv ⊕-comm-iso (inr b) = refl

-- By explicitly passing the implicit arguments, the constraint solver unblocks
⊕-comm : ∀ (A B : Mesh) (x : Space) → ⟦ A ⊕ B ⟧ x ≡ ⟦ B ⊕ A ⟧ x
⊕-comm A B x = ua (isoToEquiv (⊕-comm-iso {A} {B} {x}))
