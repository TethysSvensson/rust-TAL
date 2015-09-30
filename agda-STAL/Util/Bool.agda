module Util.Bool where

open import Data.Bool using (Bool ; true ; false) public

open import Data.Product using (_,_)
open import Util.Eq
open import Util.Tree
open import Util.Maybe

instance
  Bool-ToTree : ToTree Bool
  Bool-ToTree = tree⋆ (λ { (node 0 _) → Just true   ; _     → Just false })
                      (λ { true       → T₀ 0 , refl ; false → T₀ 1 , refl})
