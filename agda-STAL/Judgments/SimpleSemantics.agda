module Judgments.SimpleSemantics where

open import Util
open import Judgments.Syntax
open SimpleSyntax

-- The purpose of this file is to define the
-- small-step semantics for the simple syntax

evalSmallValueₛ : Vec WordValue ♯regs → SmallValue → WordValue
evalSmallValueₛ regs (reg ♯r) = lookup ♯r regs
evalSmallValueₛ regs (globval lab) = globval lab
evalSmallValueₛ regs (int i) = int i

data InstantiateGlobalₛ (G : Globals) : WordValue → InstructionSequence → Set where
  instantiate-globval :
               ∀ {lab I} →
           G ↓ lab ⇒ code I →
    -----------------------------------
    InstantiateGlobalₛ G (globval lab) I

infix 3 _⊢ₛ_⇒_
data _⊢ₛ_⇒_ (G : Globals) : MutProgramState → MutProgramState → Set where
    step-add :
             ∀ {H sp regs I ♯rd ♯rs v n₁ n₂} →
                lookup ♯rs regs ≡ int n₁ →
          evalSmallValueₛ regs v ≡ int n₂ →
      ----------------------------------------------------------
      G ⊢ₛ H , register sp regs , add ♯rd ♯rs v ~> I ⇒
           H , register sp (update ♯rd (int (n₁ + n₂)) regs) , I

    step-sub :
             ∀ {H sp regs I ♯rd ♯rs v n₁ n₂} →
                lookup ♯rs regs ≡ int n₁ →
          evalSmallValueₛ regs v ≡ int n₂ →
      ----------------------------------------------------------
      G ⊢ₛ H , register sp regs , sub ♯rd ♯rs v ~> I ⇒
           H , register sp (update ♯rd (int (n₁ ∸ n₂)) regs) , I

    step-salloc :
                      ∀ {H sp regs I n} →
      -------------------------------------------------
      G ⊢ₛ H , register sp regs , salloc n ~> I ⇒
           H , register (replicate n uninit ++ sp) regs , I

    step-sfree :
                ∀ {H sp regs I n} →
      ------------------------------------------
      G ⊢ₛ H , register sp regs , sfree n ~> I ⇒
           H , register (drop n sp) regs , I

    step-sld :
             ∀ {H sp regs I ♯rd i w} →
                    sp ↓ i ⇒ w →
      --------------------------------------------
      G ⊢ₛ H , register sp regs , sld ♯rd i ~> I ⇒
           H , register sp (update ♯rd w regs) , I

    step-sst :
             ∀ {H sp sp' regs I ♯rs i} →
           sp ⟦ i ⟧← lookup ♯rs regs ⇒ sp' →
      ---------------------------------------------
      G ⊢ₛ H , register sp  regs , sst i ♯rs ~> I ⇒
           H , register sp' regs , I

    step-ld :
           ∀ {H sp regs I ♯rd ♯rs i labₕ ws w} →
             lookup ♯rs regs ≡ heapval labₕ →
                   H ↓ labₕ ⇒ tuple ws →
                     ws ↓ i ⇒ w →
      -----------------------------------------------
      G ⊢ₛ H , register sp regs , ld ♯rd ♯rs i ~> I ⇒
           H , register sp (update ♯rd w regs) , I

    step-st :
          ∀ {H H' sp regs I ♯rd i ♯rs labₕ ws ws'} →
             lookup ♯rd regs ≡ heapval labₕ →
                   H ↓ labₕ ⇒ tuple ws →
              ws ⟦ i ⟧← lookup ♯rs regs ⇒ ws' →
                 H ⟦ labₕ ⟧← tuple ws' ⇒ H' →
      ------------------------------------------------
      G ⊢ₛ H  , register sp regs , st ♯rd i ♯rs ~> I ⇒
           H' , register sp regs , I

    step-malloc :
                    ∀ {H sp regs I ♯rd n} →
      -----------------------------------------------------------
      G ⊢ₛ H , register sp regs , malloc ♯rd n ~> I ⇒
           H ∷ʳ tuple (replicate n uninit) ,
           register sp (update ♯rd (heapval (length H)) regs) , I

    step-mov :
                       ∀ {H sp regs I ♯rd v} →
      -------------------------------------------------------------------
      G ⊢ₛ H , register sp regs , mov ♯rd v ~> I ⇒
           H , register sp (update ♯rd (evalSmallValueₛ regs v) regs) , I

    step-beq₀ :
                  ∀ {H sp regs ♯r v I₁ I₂} →
                   lookup ♯r regs ≡ int 0 →
      InstantiateGlobalₛ G (evalSmallValueₛ regs v) I₂ →
      --------------------------------------------------
         G ⊢ₛ H , register sp regs , beq ♯r v ~> I₁ ⇒
              H , register sp regs , I₂

    step-beq₁ :
                ∀ {H sp regs I ♯r v n₀} →
              lookup ♯r regs ≡ int n₀ →
                        n₀ ≢ 0 →
      -------------------------------------------
      G ⊢ₛ H , register sp regs , beq ♯r v ~> I ⇒
           H , register sp regs , I

    step-jmp :
                    ∀ {H sp regs v I} →
      InstantiateGlobalₛ G (evalSmallValueₛ regs v) I →
      -------------------------------------------------
         G ⊢ₛ H , register sp regs , jmp v ⇒
              H , register sp regs , I

infix 3 ⊢ₛ_⇒_
data ⊢ₛ_⇒_ : ProgramState → ProgramState → Set where
  step-inner :
            ∀ {G H R I H' R' I'} →
     G ⊢ₛ (H , R , I) ⇒ (H' , R' , I') →
    --------------------------------------
    ⊢ₛ (G , H , R , I) ⇒ (G , H' , R' , I')

infix 3 ⊢ₛ_⇒ₙ_/_
infixr 5 _∷_
data ⊢ₛ_⇒ₙ_/_ : ProgramState → ℕ → ProgramState → Set where
  []  :
       ∀ {P} →
    -------------
    ⊢ₛ P ⇒ₙ 0 / P

  _∷_ :
       ∀ {P₁ P₂ P₃ n} →
          ⊢ₛ P₁ ⇒ P₂ →
       ⊢ₛ P₂ ⇒ₙ n / P₃ →
      -------------------
      ⊢ₛ P₁ ⇒ₙ suc n / P₃

data Haltingₛ : ProgramState → Set where
  halting :
           ∀ {G H R} →
    ---------------------------
    Haltingₛ (G , H , R , halt)

data Progressingₛ : ProgramState → Set where
  progressing :
      ∀ {P P'} →
      ⊢ₛ P ⇒ P' →
    --------------
    Progressingₛ P

data GoodStateₛ : ProgramState → Set where
  halting :
           ∀ {G H R} →
    -----------------------------
    GoodStateₛ (G , H , R , halt)

  progressing :
     ∀ {P P'} →
     ⊢ₛ P ⇒ P' →
    ------------
    GoodStateₛ P
