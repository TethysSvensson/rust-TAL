module Judgments.Terms where

open import Util
open import Judgments.Grammar
open import Judgments.Types
open import Judgments.Substitution
open import Judgments.StackOperations
open HighGrammar

lookup-regs : Register → RegisterAssignment → Type
lookup-regs ♯r (registerₐ sp regs) = lookup ♯r regs

update-regs : Register → Type → RegisterAssignment → RegisterAssignment
update-regs ♯r τ (registerₐ sp regs) = registerₐ sp (update ♯r τ regs)


infix 3 _⊢_of_instantiation
data _⊢_of_instantiation (Δ : TypeAssumptions) : Instantiation → TypeAssumptionValue → Set where
  of-α :
           ∀ {τ} →
         Δ ⊢ τ Valid →
    --------------------------
    Δ ⊢ α τ of α instantiation

  of-ρ :
           ∀ {σ} →
         Δ ⊢ σ Valid →
    --------------------------
    Δ ⊢ ρ σ of ρ instantiation

infix 3 _⊢_of_instantiations
data _⊢_of_instantiations (Δ : TypeAssumptions) : Instantiations → TypeAssumptions → Set where
  [] :
    Δ ⊢ [] of [] instantiations

  _∷_ :
             ∀ {θ θs a Δ'} →
      Δ' ++ Δ ⊢ θ of a instantiation →
        Δ ⊢ θs of Δ' instantiations →
    -----------------------------------
    Δ ⊢ θ ∷ θs of a ∷ Δ' instantiations

infix 3 _⊢_of_wval
data _⊢_of_wval : GlobalLabelAssignment × HeapLabelAssignment →
                  WordValue → Type → Set where
  of-globval :
          ∀ {ψ₁ ψ₂ lab τ₁ τ₂} →
           ψ₁ ↓ lab ⇒ τ₁ →
           [] ⊢ τ₁ ≤ τ₂ →
    --------------------------------
    ψ₁ , ψ₂ ⊢ globval lab of τ₂ wval

  of-heapval :
           ∀ {ψ₁ ψ₂ labₕ τ₁ τ₂} →
             ψ₂ ↓ labₕ ⇒ τ₁ →
              [] ⊢ τ₁ ≤ τ₂ →
    ---------------------------------
    ψ₁ , ψ₂ ⊢ heapval labₕ of τ₂ wval

  of-int :
           ∀ {ψ₁ ψ₂ n} →
    ---------------------------
    ψ₁ , ψ₂ ⊢ int n of int wval

  of-ns :
          ∀ {ψ₁ ψ₂} →
    -----------------------
    ψ₁ , ψ₂ ⊢ uninit of ns wval

  of-Λ :
          ∀ {ψ₁ ψ₂ Δ₁ Δ₂ Γ₁ Γ₂ Γ₃ w θs} →
         ψ₁ , ψ₂ ⊢ w of ∀[ Δ₁ ] Γ₁ wval →
           Δ₂ ⊢ θs of Δ₁ instantiations →
                Γ₁ ⟦ θs / 0 ⟧many≡ Γ₂ →
                  Δ₂ ⊢ Γ₃ ≤ Γ₂ →
    --------------------------------------------
    ψ₁ , ψ₂ ⊢ Λ Δ₂ ∙ w ⟦ θs ⟧ of ∀[ Δ₂ ] Γ₃ wval

infix 3 _⊢_of_wval⁰
data _⊢_of_wval⁰ : GlobalLabelAssignment × HeapLabelAssignment →
                   WordValue → InitType → Set where
  of-uninit :
                ∀ {ψ₁ ψ₂ τ} →
               [] ⊢ τ Valid →
    ------------------------------------
    ψ₁ , ψ₂ ⊢ uninit of τ , uninit wval⁰

  of-init :
         ∀ {ψ₁ ψ₂ w τ φ} →
      ψ₁ , ψ₂ ⊢ w of τ wval →
    --------------------------
    ψ₁ , ψ₂ ⊢ w of τ , φ wval⁰

infix 3 _⊢_of_vval
data _⊢_of_vval : GlobalLabelAssignment ×
                  TypeAssumptions × RegisterAssignment →
                  SmallValue → Type → Set where
  of-reg :
           ∀ {ψ₁ Δ Γ ♯r} →
    --------------------------------------------
    ψ₁ , Δ , Γ ⊢ reg ♯r of lookup-regs ♯r Γ vval

  of-globval :
             ∀ {ψ₁ Δ Γ lab τ} →
               ψ₁ ↓ lab ⇒ τ →
    ----------------------------------
    ψ₁ , Δ , Γ ⊢ globval lab of τ vval

  of-int :
           ∀ {ψ₁ Δ Γ n} →
    ---------------------------
    ψ₁ , Δ , Γ ⊢ int n of int vval

  of-Λ :
              ∀ {ψ₁ Δ Γ Δ₁ Δ₂ Γ₁ Γ₂ v θs} →
             ψ₁ , Δ , Γ ⊢ v of ∀[ Δ₁ ] Γ₁ vval →
             Δ₂ ++ Δ ⊢ θs of Δ₁ instantiations →
    weaken (length Δ₁) (length Δ₂) Γ₁ ⟦ θs / 0 ⟧many≡ Γ₂ →
    ------------------------------------------------------
       ψ₁ , Δ , Γ ⊢ Λ Δ₂ ∙ v ⟦ θs ⟧ of ∀[ Δ₂ ] Γ₂ vval

infix 3 _⊢_of_hval
data _⊢_of_hval : GlobalLabelAssignment × HeapLabelAssignment →
                  HeapValue → Type → Set where
  of-tuple :
                     ∀ {ψ₁ ψ₂ ws τs⁻} →
    AllZip (λ w τ⁻ → ψ₁ , ψ₂ ⊢ w of τ⁻ wval⁰) ws τs⁻ →
    -------------------------------------------------------
           ψ₁ , ψ₂ ⊢ tuple ws of tuple τs⁻ hval

infix 3 _⊢_of_heap
data _⊢_of_heap (ψ₁ : GlobalLabelAssignment) (H : Heap)
                (ψ₂ : HeapLabelAssignment) : Set where
  of-heap :
    AllZip (λ h τ → ψ₁ , ψ₂ ⊢ h of τ hval) H ψ₂ →
    ---------------------------------------------
                ψ₁ ⊢ H of ψ₂ heap

infix 3 _⊢_of_stack
infixr 5 _∷_
data _⊢_of_stack : GlobalLabelAssignment × HeapLabelAssignment →
                   Stack → StackType → Set where
  [] :
            ∀ {ψ₁ ψ₂} →
    -------------------------
    ψ₁ , ψ₂ ⊢ [] of [] stack

  _∷_ :
         ∀ {ψ₁ ψ₂ w S τ σ} →
        ψ₁ , ψ₂ ⊢ w of τ wval →
        ψ₁ , ψ₂ ⊢ S of σ stack →
    ------------------------------
    ψ₁ , ψ₂ ⊢ w ∷ S of τ ∷ σ stack

infix 3 _⊢_of_register
data _⊢_of_register : GlobalLabelAssignment ×
                      HeapLabelAssignment →
                      RegisterFile → RegisterAssignment → Set where
  of-register :
                   ∀ {ψ₁ ψ₂ sp regs σ τs} →
                   ψ₁ , ψ₂ ⊢ sp of σ stack →
    AllZipᵥ (λ w τ → ψ₁ , ψ₂ ⊢ w of τ wval) regs τs →
    ------------------------------------------------------
     ψ₁ , ψ₂ ⊢ register sp regs of registerₐ σ τs register

infix 3 _⊢_of_instruction
data _⊢_of_instruction : GlobalLabelAssignment × TypeAssumptions ×
                        RegisterAssignment →
                        Instruction → RegisterAssignment → Set where
  of-add :
                   ∀ {ψ₁ Δ Γ ♯rd ♯rs v} →
                  lookup-regs ♯rs Γ ≡ int →
                 ψ₁ , Δ , Γ ⊢ v of int vval →
    ---------------------------------------------------------------
    ψ₁ , Δ , Γ ⊢ add ♯rd ♯rs v of update-regs ♯rd int Γ instruction

  of-sub :
                     ∀ {ψ₁ Δ Γ ♯rd ♯rs v} →
                   lookup-regs ♯rs Γ ≡ int →
                  ψ₁ , Δ , Γ ⊢ v of int vval →
    ---------------------------------------------------------------
    ψ₁ , Δ , Γ ⊢ sub ♯rd ♯rs v of update-regs ♯rd int Γ instruction

  of-salloc :
              ∀ {ψ₁ Δ sp regs n} →
    ----------------------------------------------------------------------
    ψ₁ , Δ , registerₐ sp regs ⊢ salloc n of
             registerₐ (stack-append (replicate n ns) sp) regs instruction

  of-sfree :
                           ∀ {ψ₁ Δ sp sp' regs n} →
                             stack-drop n sp sp' →
    ----------------------------------------------------------------------
    ψ₁ , Δ , registerₐ sp regs ⊢ sfree n of registerₐ sp' regs instruction

  of-sld :
                       ∀ {ψ₁ Δ sp regs ♯rd i τ} →
                          stack-lookup i sp τ →
    --------------------------------------------------------------------------------------
    ψ₁ , Δ , registerₐ sp regs ⊢ sld ♯rd i of registerₐ sp (update ♯rd τ regs) instruction

  of-sst :
                    ∀ {ψ₁ Δ sp sp' regs i ♯rs} →
                  stack-update i (lookup ♯rs regs) sp sp' →
    ------------------------------------------------------------------------
    ψ₁ , Δ , registerₐ sp regs ⊢ sst i ♯rs of registerₐ sp' regs instruction

  of-ld :
                  ∀ {ψ₁ Δ Γ ♯rd ♯rs i τs⁻ τ} →
                 lookup-regs ♯rs Γ ≡ tuple τs⁻ →
                      τs⁻ ↓ i ⇒ τ , init →
    ------------------------------------------------------------
    ψ₁ , Δ , Γ ⊢ ld ♯rd ♯rs i of update-regs ♯rd τ Γ instruction

  of-st :
                 ∀ {ψ₁ Δ Γ ♯rd i ♯rs τ τs⁻ τs⁻' φ} →
                   lookup-regs ♯rd Γ ≡ tuple τs⁻ →
                       Δ ⊢ lookup-regs ♯rs Γ ≤ τ →
                         τs⁻ ↓ i ⇒ τ , φ →
                    τs⁻ ⟦ i ⟧← τ , init ⇒ τs⁻' →
    -----------------------------------------------------------------------
    ψ₁ , Δ , Γ ⊢ st ♯rd i ♯rs of update-regs ♯rd (tuple τs⁻') Γ instruction

  of-malloc :
                    ∀ {ψ₁ Δ Γ ♯rd τs} →
                      Δ ⊢ τs Valid →
    -------------------------------------------------------------------
    ψ₁ , Δ , Γ ⊢ malloc ♯rd τs of
      update-regs ♯rd (tuple (map (λ τ → τ , uninit) τs)) Γ instruction

  of-mov :
                    ∀ {ψ₁ Δ Γ ♯rd v τ} →
                  ψ₁ , Δ , Γ ⊢ v of τ vval →
    ---------------------------------------------------------
    ψ₁ , Δ , Γ ⊢ mov ♯rd v of update-regs ♯rd τ Γ instruction

  of-beq :
           ∀ {ψ₁ Δ ♯r v Γ Γ'} →
         lookup-regs ♯r Γ ≡ int →
    ψ₁ , Δ , Γ ⊢ v of ∀[ [] ] Γ' vval →
               Δ ⊢ Γ ≤ Γ' →
    -------------------------------------
    ψ₁ , Δ , Γ ⊢ beq ♯r v of Γ instruction

infix 3 _⊢_instructionsequence
data _⊢_instructionsequence : GlobalLabelAssignment ×
                              TypeAssumptions ×
                              RegisterAssignment →
                              InstructionSequence → Set where
  of-~> :
          ∀ {ψ₁ Δ Γ Γ' ι I} →
    ψ₁ , Δ , Γ  ⊢ ι of Γ' instruction →
    ψ₁ , Δ , Γ' ⊢ I instructionsequence →
    ---------------------------------------
    ψ₁ , Δ , Γ ⊢ ι ~> I instructionsequence

  of-jmp :
            ∀ {ψ₁ Δ Γ Γ' v} →
     ψ₁ , Δ , Γ ⊢ v of ∀[ [] ] Γ' vval →
               Δ ⊢ Γ ≤ Γ' →
    --------------------------------------
    ψ₁ , Δ , Γ ⊢ jmp v instructionsequence

  of-halt :
                ∀ {ψ₁ Δ Γ} →
    -------------------------------------
    ψ₁ , Δ , Γ ⊢ halt instructionsequence

infix 3 _⊢_of_gval
data _⊢_of_gval (ψ₁ : GlobalLabelAssignment) : GlobalValue →
                                               Type → Set where
  of-gval :
               ∀ {Δ Γ I} →
              Δ ⊢ Γ Valid →
    ψ₁ , Δ , Γ ⊢ I instructionsequence →
    -------------------------------------
    ψ₁ ⊢ code[ Δ ] Γ ∙ I of ∀[ Δ ] Γ gval

infix 3 ⊢_of_globals
data ⊢_of_globals (G : Globals) (ψ₁ : GlobalLabelAssignment) : Set where
  of-globals :
    AllZip (λ g τ → ψ₁ ⊢ g of τ gval) G ψ₁ →
    ----------------------------------------
             ⊢ G of ψ₁ globals

infix 3 _⊢_of_programstate
data _⊢_of_programstate : GlobalLabelAssignment → ProgramState → HeapLabelAssignment × RegisterAssignment → Set where
  of-programstate :
            ∀ {ψ₁ ψ₂ Γ H R I} →
             ψ₁ ⊢ H of ψ₂ heap →
         ψ₁ , ψ₂ ⊢ R of Γ register →
    ψ₁ , [] , Γ ⊢ I instructionsequence →
    -------------------------------------
    ψ₁ ⊢ H , R , I of ψ₂ , Γ programstate

infix 3 ⊢_program
data ⊢_program : Program → Set where
  of-running :
            ∀ {G ψ₁ ψ₂ Γ P} →
           ⊢ G of ψ₁ globals →
    ψ₁ ⊢ P of ψ₂ , Γ programstate →
    -------------------------------
        ⊢ running G P program

  of-halted :
    ----------------
    ⊢ halted program
