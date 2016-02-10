module Lemmas.EmbedSimulation where

open import Util
open import Judgments
open import Lemmas.HighSemantics
open import Lemmas.SimpleSemantics

-- The purpose of this module is to prove that
-- the relation {(ℒₕ, embed ℒₕ)} is a simulation.

private
  module S where
    open SimpleGrammar public
    open SimpleSemantics public

  module H where
    open HighGrammar public
    open HighSemantics public

  embed-↓ : ∀ {A B : Set} {{E : Embed A B}}
              {xs : List A} {i x} →
              xs ↓ i ⇒ x →
              map embed xs ↓ i ⇒ embed x
  embed-↓ here = here
  embed-↓ (there l) = there (embed-↓ l)

  embed-← : ∀ {A B : Set} {{E : Embed A B}}
                 {xs xs' : List A} {i x} →
                 xs ⟦ i ⟧← x ⇒ xs' →
                 map embed xs ⟦ i ⟧← embed x ⇒ map embed xs'
  embed-← here = here
  embed-← (there l) = there (embed-← l)

  embed-lookup : ∀ {A B : Set} {{E : Embed A B}}
                {n} i (xs : Vec A n) →
                embed (lookup i xs) ≡ lookup i (Vec-map embed xs)
  embed-lookup zero (x ∷ xs) = refl
  embed-lookup (suc i) (x ∷ xs) = embed-lookup i xs

  embed-update : ∀ {A B : Set} {{E : Embed A B}}
                   {n} i x (xs : Vec A n) →
                   Vec-map embed (update i x xs) ≡ update i (embed x) (Vec-map embed xs)
  embed-update i x xs = map-[]≔ embed xs i

  drop-helper : ∀ {n} {sp sp' : H.Stack} →
                  Drop n sp sp' →
                  embed sp' ≡ drop n (embed sp)
  drop-helper here = refl
  drop-helper (there drop) = drop-helper drop

  replicate-helper : ∀ n → embed {{embedListWordValue}} (replicate n uninit) ≡ replicate n uninit
  replicate-helper zero = refl
  replicate-helper (suc n) = cong₂ _∷_ refl (replicate-helper n)

  embed-subst-v : ∀ {v v' : H.SmallValue} {θ pos} →
                    v ⟦ θ / pos ⟧≡ v' →
                    embed v ≡ embed v'
  embed-subst-v subst-reg = refl
  embed-subst-v subst-globval = refl
  embed-subst-v subst-int = refl
  embed-subst-v (subst-Λ sub-v subs-I) = embed-subst-v sub-v

  embed-subst-ι : ∀ {ι ι' : H.Instruction} {θ pos} →
                    ι ⟦ θ / pos ⟧≡ ι' →
                    embed ι ≡ embed ι'
  embed-subst-ι {add ♯rd ♯rs v} (subst-add sub-v) = cong (add ♯rd ♯rs) (embed-subst-v sub-v)
  embed-subst-ι {sub ♯rd ♯rs v} (subst-sub sub-v) = cong (sub ♯rd ♯rs) (embed-subst-v sub-v)
  embed-subst-ι subst-salloc = refl
  embed-subst-ι subst-sfree = refl
  embed-subst-ι subst-sld = refl
  embed-subst-ι subst-sst = refl
  embed-subst-ι subst-ld = refl
  embed-subst-ι subst-st = refl
  embed-subst-ι (subst-malloc sub-τs) = cong₂ malloc refl (help sub-τs)
    where help : ∀ {τs τs' : List Type} {θ pos} →
                   τs ⟦ θ / pos ⟧≡ τs' →
                   length τs ≡ length τs'
          help [] = refl
          help (sub-τ ∷ sub-τs) = cong suc (help sub-τs)

  embed-subst-ι (subst-mov sub-v) = cong₂ mov refl (embed-subst-v sub-v)
  embed-subst-ι (subst-beq sub-v) = cong₂ beq refl (embed-subst-v sub-v)

  embed-subst-I : ∀ {I I' : H.InstructionSequence} {θ pos} →
                    I ⟦ θ / pos ⟧≡ I' →
                    embed I ≡ embed I'
  embed-subst-I (subst-~> sub-ι sub-I) = cong₂ _~>_ (embed-subst-ι sub-ι) (embed-subst-I sub-I)
  embed-subst-I (subst-jmp sub-v) = cong jmp (embed-subst-v sub-v)
  embed-subst-I subst-halt = refl

  embed-subst-I-many : ∀ {I I' : H.InstructionSequence} {θs pos} →
                         I ⟦ θs / pos ⟧many≡ I' →
                         embed I ≡ embed I'
  embed-subst-I-many [] = refl
  embed-subst-I-many (sub-I ∷ subs-I)
    rewrite embed-subst-I sub-I
      = embed-subst-I-many subs-I

  embed-eval : ∀ regs v →
                 embed (H.evalSmallValue regs v) ≡ S.evalSmallValue (embed regs) (embed v)
  embed-eval regs (reg ♯r) = embed-lookup ♯r regs
  embed-eval regs (globval lab) = refl
  embed-eval regs (int i) = refl
  embed-eval regs Λ Δ ∙ v ⟦ θs ⟧ = embed-eval regs v

  embed-instantiate : ∀ {G w I} →
                        H.InstantiateGlobal G w I →
                        S.InstantiateGlobal (embed G) (embed w) (embed I)
  embed-instantiate (instantiate-globval l) = instantiate-globval (embed-↓ l)
  embed-instantiate (instantiate-Λ ig subs-I)
    with embed-instantiate ig
  ... | ig'
    rewrite embed-subst-I-many subs-I
      = ig'

  embed-step : ∀ {G P P'} →
                 G H.⊢ P ⇒ P' →
                 embed G S.⊢ embed P ⇒ embed P'
  embed-step (step-add {regs = regs} {♯rd = ♯rd} {♯rs} {v} {n₁} {n₂} eq₁ eq₂)
    rewrite embed-update ♯rd (int (n₁ + n₂)) regs
          = step-add (trans (sym (embed-lookup ♯rs regs)) (cong embed eq₁))
                     (trans (sym (embed-eval regs v)) (cong embed eq₂))
  embed-step (step-sub {regs = regs} {♯rd = ♯rd} {♯rs} {v} {n₁} {n₂} eq₁ eq₂)
    rewrite embed-update ♯rd (int (n₁ ∸ n₂)) regs
          = step-sub (trans (sym (embed-lookup ♯rs regs)) (cong embed eq₁))
                     (trans (sym (embed-eval regs v)) (cong embed eq₂))
  embed-step (step-salloc {sp = sp} {n = n})
    rewrite List-map-++-commute embed (replicate n uninit) sp
          | replicate-helper n
      = step-salloc
  embed-step (step-sfree drop)
    rewrite drop-helper drop
      = step-sfree
  embed-step (step-sld {regs = regs} {♯rd = ♯rd} {w = w} l)
    rewrite embed-update ♯rd w regs
      = step-sld (embed-↓ l)
  embed-step (step-sst {regs = regs} {♯rs = ♯rs} up)
    with embed-← up
  ... | up'
    rewrite embed-lookup ♯rs regs
      = step-sst up'
  embed-step (step-ld {regs = regs} {♯rd = ♯rd} {♯rs} {w = w} eq l₁ l₂)
    rewrite embed-update ♯rd w regs
    = step-ld (trans (sym (embed-lookup ♯rs regs)) (cong embed eq)) (embed-↓ l₁) (embed-↓ l₂)
  embed-step (step-st {regs = regs} {♯rd = ♯rd} {♯rs = ♯rs} eq l up₁ up₂)
    with embed-← up₁
  ... | up₁'
    rewrite embed-lookup ♯rs regs
    = step-st (trans (sym (embed-lookup ♯rd regs)) (cong embed eq)) (embed-↓ l) up₁' (embed-← up₂)
  embed-step (step-malloc {H = H} {regs = regs} {♯rd = ♯rd} {τs = τs})
    rewrite List-map-++-commute embed H [ tuple τs (replicate (length τs) uninit) ]
          | replicate-helper (length τs)
          | embed-update ♯rd (heapval (length H)) regs
          | sym (List-length-map embed H)
      = step-malloc
  embed-step (step-mov {regs = regs} {♯rd = ♯rd} {v = v})
    rewrite embed-update ♯rd (H.evalSmallValue regs v) regs
          | embed-eval regs v
    = step-mov
  embed-step (step-beq₀ {regs = regs} {♯r = ♯r} {v = v} eq ig)
    with embed-instantiate ig
  ... | ig'
    rewrite embed-eval regs v
    = step-beq₀ (trans (sym (embed-lookup ♯r regs)) (cong embed eq)) ig'
  embed-step (step-beq₁ {regs = regs} {♯r = ♯r} eq neq)
    = step-beq₁ (trans (sym (embed-lookup ♯r regs)) (cong embed eq)) neq
  embed-step (step-jmp {regs = regs} {v = v} ig)
    with embed-instantiate ig
  ... | ig'
    rewrite embed-eval regs v
    = step-jmp ig'

embed-step-prg : ∀ {ℒ ℒ'} →
                   H.⊢ ℒ ⇒ ℒ' →
                   S.⊢ embed ℒ ⇒ embed ℒ'
embed-step-prg (step-running step) = step-running (embed-step step)
embed-step-prg step-halting = step-halting
embed-step-prg step-halted = step-halted

embed-stuck : ∀ {ℒ} →
              ¬ H.Stuck ℒ →
              ¬ S.Stuck (embed ℒ)
embed-stuck ¬stuck stuck with ¬Stuck→stepₕ ¬stuck
embed-stuck ¬stuck (here ¬step)       | ℒ' , step' , ¬stuck' = ¬step (_ , embed-step-prg step')
embed-stuck ¬stuck (there step stuck) | ℒ' , step' , ¬stuck'
  rewrite step-prg-uniqueₛ step (embed-step-prg step')
    = embed-stuck ¬stuck' stuck