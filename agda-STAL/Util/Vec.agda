module Util.Vec where

open import Data.Vec using (Vec ; [] ; _∷_ ; toList ; fromList) renaming (map to Vec-map) public
open import Data.Vec.Properties using () renaming (∷-injective to Vec-∷-injective) public

open import Util.Dec
open import Util.Tree
open import Util.Maybe
open import Util.Function

open import Data.Nat using (zero ; suc)
open import Relation.Binary.PropositionalEquality using (cong₂)
open import Data.List using (List ; map ; [] ; _∷_)

repeat : ∀ {a} {A : Set a} {m} → A → Vec A m
repeat {m = zero}  x = []
repeat {m = suc i} x = x ∷ repeat x

instance
  Vec-Tree : ∀ {ℓ} {A : Set ℓ} {{_ : ToTree A}} {m} →
                 ToTree (Vec A m)
  Vec-Tree = tree to from eq
    where to : ∀ {ℓ} {A : Set ℓ} {{t : ToTree A}} {m} → Vec A m → Tree
          to xs = node 0 (map toTree (toList xs))
          from' : ∀ {ℓ} {A : Set ℓ} {{t : ToTree A}} {m} → List Tree → ¿ Vec A m
          from' {{t}} {zero} [] = Just []
          from' {{t}} {zero} (x ∷ xs) = Nothing
          from' {{t}} {suc i} [] = Nothing
          from' {{t}} {suc i} (x ∷ xs) = _∷_ <$> fromTree {{t}} x <*> from' {{t}} {i} xs
          from : ∀ {ℓ} {A : Set ℓ} {{t : ToTree A}} {m} → Tree → ¿ Vec A m
          from (node _ xs) = from' xs
          eq : ∀ {ℓ} {A : Set ℓ} {{t : ToTree A}} {m} → IsInverse (to {m = m}) (from {{t}})
          eq [] = refl
          eq (x ∷ xs) = _∷_ <$=> invTree x <*=> eq xs
