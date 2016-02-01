module Lemmas.Equality where

open import Util
open import Judgments
private module S = SimpleGrammar
private module H = HighGrammar

-- The purpose of this file is implement a
-- ToTree instance to every element in the
-- grammar, since this causes them to also
-- implement DecEq.

private
  mutual
    τ-from : Tree → Maybe Type
    τ-from (node 0 (ι ∷ _)) = α⁼ <$> fromTree ι
    τ-from (node 1 _) = just int
    τ-from (node 2 _) = just ns
    τ-from (node 3 (Δ ∷ Γ ∷ _)) = ∀[_]_ <$> Δ-from Δ <*> Γ-from Γ
    τ-from (node 4 τs) = tuple <$> τs-from τs
    τ-from _ = nothing

    τ-sur : IsSurjective τ-from
    τ-sur (α⁼ ι) = T₁ 0 ι , refl
    τ-sur int = T₀ 1 , refl
    τ-sur ns = T₀ 2 , refl
    τ-sur (∀[ Δ ] Γ) = T₂ 3 (proj₁ (Δ-sur Δ)) (proj₁ (Γ-sur Γ)) ,
      ∀[_]_ <$=> proj₂ (Δ-sur Δ) <*=> proj₂ (Γ-sur Γ)
    τ-sur (tuple τs) = node 4 (proj₁ (τs-sur τs)) ,
      tuple <$=> proj₂ (τs-sur τs)

    φ-from : Tree → Maybe InitializationFlag
    φ-from (node 0 _) = just init
    φ-from _ = just uninit

    φ-sur : IsSurjective φ-from
    φ-sur init = T₀ 0 , refl
    φ-sur uninit = T₀ 1 , refl

    τs-from : List Tree → Maybe (List InitType)
    τs-from [] = just []
    τs-from (node _ (τ ∷ φ ∷ _) ∷ τs) =
      (λ τ φ τs → (τ , φ) ∷ τs)
        <$> τ-from τ <*> φ-from φ <*> τs-from τs
    τs-from _ = nothing

    τs-sur : IsSurjective τs-from
    τs-sur [] = [] , refl
    τs-sur ((τ , φ) ∷ τs) =
      T₂ 0 (proj₁ (τ-sur τ)) (proj₁ (φ-sur φ)) ∷ proj₁ (τs-sur τs) ,
      (λ τ φ τs → (τ , φ) ∷ τs)
        <$=> proj₂ (τ-sur τ) <*=> proj₂ (φ-sur φ) <*=> proj₂ (τs-sur τs)

    σ-from : Tree → Maybe StackType
    σ-from (node 0 (ι ∷ _)) = ρ⁼ <$> fromTree ι
    σ-from (node 1 _) = just []
    σ-from (node 2 (τ ∷ σ ∷ _)) = _∷_ <$> τ-from τ <*> σ-from σ
    σ-from _ = nothing

    σ-sur : IsSurjective σ-from
    σ-sur (ρ⁼ ι) = T₁ 0 ι , refl
    σ-sur [] = T₀ 1 , refl
    σ-sur (τ ∷ σ) = T₂ 2 (proj₁ (τ-sur τ)) (proj₁ (σ-sur σ)) ,
      _∷_ <$=> proj₂ (τ-sur τ) <*=> proj₂ (σ-sur σ)

    Δ-from : Tree → Maybe TypeAssumptions
    Δ-from (node 0 _) = just []
    Δ-from (node 1 (a ∷ Δ ∷ _)) = _∷_ <$> a-from a <*> Δ-from Δ
    Δ-from _ = nothing

    Δ-sur : IsSurjective Δ-from
    Δ-sur [] = T₀ 0 , refl
    Δ-sur (a ∷ Δ) = T₂ 1 (proj₁ (a-sur a)) (proj₁ (Δ-sur Δ)) ,
      _∷_ <$=> proj₂ (a-sur a) <*=> proj₂ (Δ-sur Δ)

    a-from : Tree → Maybe TypeAssumptionValue
    a-from (node 0 _) = just α
    a-from (node 1 _) = just ρ
    a-from _ = nothing

    a-sur : IsSurjective a-from
    a-sur α = T₀ 0 , refl
    a-sur ρ = T₀ 1 , refl

    Γ-from : Tree → Maybe RegisterAssignment
    Γ-from (node _ (sp ∷ regs)) =
      registerₐ <$> σ-from sp <*> regs-from regs
    Γ-from _ = nothing

    Γ-sur : IsSurjective Γ-from
    Γ-sur (registerₐ sp regs) =
      node 0 (proj₁ (σ-sur sp) ∷ proj₁ (regs-sur regs)) ,
      registerₐ <$=> proj₂ (σ-sur sp) <*=> proj₂ (regs-sur regs)

    regs-from : ∀ {m} → List Tree → Maybe (Vec Type m)
    regs-from {zero}  []       = just []
    regs-from {zero}  (τ ∷ τs) = nothing
    regs-from {suc m} []       = nothing
    regs-from {suc m} (τ ∷ τs) = _∷_ <$> τ-from τ <*> regs-from τs

    regs-sur : ∀ {m} → IsSurjective (regs-from {m})
    regs-sur [] = [] , refl
    regs-sur (τ ∷ τs) = (proj₁ (τ-sur τ) ∷ proj₁ (regs-sur τs)) ,
      _∷_ <$=> proj₂ (τ-sur τ) <*=> proj₂ (regs-sur τs)

instance
  WordValueₛ-Tree : ToTree S.WordValue
  WordValueₛ-Tree = tree⋆ from sur
    where from : Tree → Maybe S.WordValue
          from (node 0 (l ∷ _)) = globval <$> fromTree l
          from (node 1 (lₕ ∷ _)) = heapval <$> fromTree lₕ
          from (node 2 (n ∷ _)) = int <$> fromTree n
          from (node 3 _) = just ns
          from (node 4 _) = just uninit
          from _ = nothing
          sur : IsSurjective from
          sur (globval l) = T₁ 0 l , globval <$=> invTree l
          sur (heapval lₕ) = T₁ 1 lₕ , heapval <$=> invTree lₕ
          sur (int n) = T₁ 2 n , int <$=> invTree n
          sur ns = T₀ 3 , refl
          sur uninit = T₀ 4 , refl

  SmallValueₛ-Tree : ToTree S.SmallValue
  SmallValueₛ-Tree = tree⋆ from sur
    where from : Tree → Maybe S.SmallValue
          from (node 0 (♯r ∷ _)) = reg <$> fromTree ♯r
          from (node 1 (l ∷ _)) = globval <$> fromTree l
          from (node 2 (n ∷ _)) = int <$> fromTree n
          from _ = nothing
          sur : IsSurjective from
          sur (reg ♯r) = T₁ 0 ♯r , reg <$=> invTree ♯r
          sur (globval l) = T₁ 1 l , globval <$=> invTree l
          sur (int n) = T₁ 2 n , int <$=> invTree n

  Instructionₛ-Tree : ToTree S.Instruction
  Instructionₛ-Tree = tree⋆ from sur
    where from : Tree → Maybe S.Instruction
          from (node 0 (♯r₁ ∷ ♯r₂ ∷ v ∷ _)) =
            add <$> fromTree ♯r₁ <*> fromTree ♯r₂ <*> fromTree v
          from (node 1 (♯r₁ ∷ ♯r₂ ∷ v ∷ _)) =
            sub <$> fromTree ♯r₁ <*> fromTree ♯r₂ <*> fromTree v
          from (node 2 (n ∷ _)) = salloc <$> fromTree n
          from (node 3 (n ∷ _)) = sfree <$> fromTree n
          from (node 4 (♯r ∷ i ∷ _)) = sld <$> fromTree ♯r <*> fromTree i
          from (node 5 (i ∷ ♯r ∷ _)) = sst <$> fromTree i <*> fromTree ♯r
          from (node 6 (♯r₁ ∷ ♯r₂ ∷ i ∷ _)) =
            ld <$> fromTree ♯r₁ <*> fromTree ♯r₂ <*> fromTree i
          from (node 7 (♯r₁ ∷ i ∷ ♯r₂ ∷ _)) =
            st <$> fromTree ♯r₁ <*> fromTree i <*> fromTree ♯r₂
          from (node 8 (♯rd ∷ τs ∷ _)) =
            malloc <$> fromTree ♯rd <*> fromTree τs
          from (node 9 (♯rd ∷ v ∷ _)) =
            mov <$> fromTree ♯rd <*> fromTree v
          from (node 10 (♯r ∷ v ∷ _)) =
            beq <$> fromTree ♯r <*> fromTree v
          from _ = nothing
          sur : IsSurjective from
          sur (add ♯r₁ ♯r₂ v) = T₃ 0 ♯r₁ ♯r₂ v ,
            add <$=> invTree ♯r₁ <*=> invTree ♯r₂ <*=> invTree v
          sur (sub ♯r₁ ♯r₂ v) = T₃ 1 ♯r₁ ♯r₂ v ,
            sub <$=> invTree ♯r₁ <*=> invTree ♯r₂ <*=> invTree v
          sur (salloc n) = T₁ 2 n , salloc <$=> invTree n
          sur (sfree n) = T₁ 3 n , sfree <$=> invTree n
          sur (sld ♯r i) = T₂ 4 ♯r i , sld <$=> invTree ♯r <*=> invTree i
          sur (sst i ♯r) = T₂ 5 i ♯r , sst <$=> invTree i <*=> invTree ♯r
          sur (ld ♯r₁ ♯r₂ i) = T₃ 6 ♯r₁ ♯r₂ i ,
            ld <$=> invTree ♯r₁ <*=> invTree ♯r₂ <*=> invTree i
          sur (st ♯r₁ i ♯r₂) = T₃ 7 ♯r₁ i ♯r₂ ,
            st <$=> invTree ♯r₁ <*=> invTree i <*=> invTree ♯r₂
          sur (malloc ♯rd τs) = T₂ 8 ♯rd τs ,
            malloc <$=> invTree ♯rd <*=> invTree τs
          sur (mov ♯rd v) = T₂ 9 ♯rd v ,
            mov <$=> invTree ♯rd <*=> invTree v
          sur (beq ♯r v) = T₂ 10 ♯r v ,
            beq <$=> invTree ♯r <*=> invTree v

  InstructionSequenceₛ-Tree : ToTree S.InstructionSequence
  InstructionSequenceₛ-Tree = tree⋆ from sur
    where from : Tree → Maybe S.InstructionSequence
          from (node 0 (ι ∷ I ∷ _)) = _~>_ <$> fromTree ι <*> from I
          from (node 1 (v ∷ _)) = jmp <$> fromTree v
          from (node 2 _) = just halt
          from _ = nothing
          sur : IsSurjective from
          sur (ι ~> I) = T₂ 0 ι (proj₁ (sur I)) ,
            _~>_ <$=> invTree ι <*=> proj₂ (sur I)
          sur (jmp v) = T₁ 1 v , jmp <$=> invTree v
          sur halt = T₀ 2 , refl

  HeapValueₛ-Tree : ToTree S.HeapValue
  HeapValueₛ-Tree = tree⋆ from sur
    where from' : List Tree → Maybe (List S.WordValue)
          from' [] = just []
          from' (t ∷ ts) = _∷_ <$> fromTree t <*> from' ts
          sur' : IsSurjective from'
          sur' [] = [] , refl
          sur' (w ∷ ws) = toTree w ∷ proj₁ (sur' ws) ,
            _∷_ <$=> invTree w <*=> proj₂ (sur' ws)
          from : Tree → Maybe S.HeapValue
          from (node _ ws) = tuple <$> from' ws
          sur : IsSurjective from
          sur (tuple ws) =
            node 0 (proj₁ (sur' ws)) ,
            tuple <$=> proj₂ (sur' ws)

  GlobalValueₛ-Tree : ToTree S.GlobalValue
  GlobalValueₛ-Tree = tree⋆
    (λ { (node _ (I ∷ _)) → code <$> fromTree I ; _ → nothing })
    (λ { (code I) → T₁ 0 I , code <$=> invTree I })

  RegisterFileₛ-Tree : ToTree S.RegisterFile
  RegisterFileₛ-Tree = tree⋆ from sur
    where from : Tree → Maybe S.RegisterFile
          from (node _ (stack ∷ regs ∷ []))
            = register <$> fromTree stack <*> fromTree regs
          from _ = nothing
          sur : IsSurjective from
          sur (register stack regs) = T₂ 0 stack regs ,
            register <$=> invTree stack <*=> invTree regs

  Programₛ-Tree : ToTree S.Program
  Programₛ-Tree = tree⋆ from sur
    where from : Tree → Maybe S.Program
          from (node 0 (G ∷ P ∷ _)) = going <$> fromTree G <*> fromTree P
          from (node 1 _) = just halted
          from _ = nothing
          sur : IsSurjective from
          sur (going G P) = T₂ 0 G P ,
            going <$=> invTree G <*=> invTree P
          sur halted = T₀ 1 , refl

  Type-Tree : ToTree Type
  Type-Tree = tree⋆ τ-from τ-sur

  InitializationFlag-Tree : ToTree InitializationFlag
  InitializationFlag-Tree = tree⋆ φ-from φ-sur

  StackType-Tree : ToTree StackType
  StackType-Tree = tree⋆ σ-from σ-sur

  TypeAssumptionValue-Tree : ToTree TypeAssumptionValue
  TypeAssumptionValue-Tree = tree⋆ a-from a-sur

  RegisterAssignment-Tree : ToTree RegisterAssignment
  RegisterAssignment-Tree = tree⋆ Γ-from Γ-sur

  Instantiation-Tree : ToTree Instantiation
  Instantiation-Tree = tree⋆ from sur
    where from : Tree → Maybe Instantiation
          from (node 0 (τ ∷ _)) = α <$> fromTree τ
          from (node 1 (σ ∷ _)) = ρ <$> fromTree σ
          from _ = nothing
          sur : IsSurjective from
          sur (α τ) = T₁ 0 τ , α <$=> invTree τ
          sur (ρ σ) = T₁ 1 σ , ρ <$=> invTree σ

  WordValueₕ-Tree : ToTree H.WordValue
  WordValueₕ-Tree = tree⋆ from sur
    where from : Tree → Maybe H.WordValue
          from (node 0 (l ∷ _)) = globval <$> fromTree l
          from (node 1 (lₕ ∷ _)) = heapval <$> fromTree lₕ
          from (node 2 (n ∷ _)) = int <$> fromTree n
          from (node 3 _) = just ns
          from (node 4 (τ ∷ _)) = uninit <$> fromTree τ
          from (node 5 (Δ ∷ w ∷ is ∷ _)) = Λ_∙_⟦_⟧ <$> fromTree Δ <*> from w <*> fromTree is
          from _ = nothing
          sur : IsSurjective from
          sur (globval l) = T₁ 0 l ,
            globval <$=> invTree l
          sur (heapval lₕ) = T₁ 1 lₕ , heapval <$=> invTree lₕ
          sur (int n) = T₁ 2 n , int <$=> invTree n
          sur ns = T₀ 3 , refl
          sur (uninit τ) = T₁ 4 τ , uninit <$=> invTree τ
          sur (Λ Δ ∙ w ⟦ is ⟧) = T₃ 5 Δ (proj₁ (sur w)) is ,
            Λ_∙_⟦_⟧ <$=> invTree Δ <*=> proj₂ (sur w) <*=> invTree is

  SmallValueₕ-Tree : ToTree H.SmallValue
  SmallValueₕ-Tree = tree⋆ from sur
    where from : Tree → Maybe H.SmallValue
          from (node 0 (♯r ∷ _)) = reg <$> fromTree ♯r
          from (node 1 (l ∷ _)) = globval <$> fromTree l
          from (node 2 (n ∷ _)) = int <$> fromTree n
          from (node 3 (Δ ∷ w ∷ is ∷ _)) = Λ_∙_⟦_⟧ <$> fromTree Δ <*> from w <*> fromTree is
          from _ = nothing
          sur : IsSurjective from
          sur (reg ♯r) = T₁ 0 ♯r , reg <$=> invTree ♯r
          sur (globval l) = T₁ 1 l , globval <$=> invTree l
          sur (int n) = T₁ 2 n , int <$=> invTree n
          sur (Λ Δ ∙ w ⟦ is ⟧) = T₃ 3 Δ (proj₁ (sur w)) is ,
            Λ_∙_⟦_⟧ <$=> invTree Δ <*=> proj₂ (sur w) <*=> invTree is

  Instructionₕ-Tree : ToTree H.Instruction
  Instructionₕ-Tree = tree⋆ from sur
    where from : Tree → Maybe H.Instruction
          from (node 0 (♯r₁ ∷ ♯r₂ ∷ v ∷ _)) =
            add <$> fromTree ♯r₁ <*> fromTree ♯r₂ <*> fromTree v
          from (node 1 (♯r₁ ∷ ♯r₂ ∷ v ∷ _)) =
            sub <$> fromTree ♯r₁ <*> fromTree ♯r₂ <*> fromTree v
          from (node 2 (n ∷ _)) = salloc <$> fromTree n
          from (node 3 (n ∷ _)) = sfree <$> fromTree n
          from (node 4 (♯r ∷ i ∷ _)) = sld <$> fromTree ♯r <*> fromTree i
          from (node 5 (i ∷ ♯r ∷ _)) = sst <$> fromTree i <*> fromTree ♯r
          from (node 6 (♯r₁ ∷ ♯r₂ ∷ i ∷ _)) =
            ld <$> fromTree ♯r₁ <*> fromTree ♯r₂ <*> fromTree i
          from (node 7 (♯r₁ ∷ i ∷ ♯r₂ ∷ _)) =
            st <$> fromTree ♯r₁ <*> fromTree i <*> fromTree ♯r₂
          from (node 8 (♯rd ∷ τs ∷ _)) =
            malloc <$> fromTree ♯rd <*> fromTree τs
          from (node 9 (♯rd ∷ v ∷ _)) =
            mov <$> fromTree ♯rd <*> fromTree v
          from (node 10 (♯r ∷ v ∷ _)) =
            beq <$> fromTree ♯r <*> fromTree v
          from _ = nothing
          sur : IsSurjective from
          sur (add ♯r₁ ♯r₂ v) = T₃ 0 ♯r₁ ♯r₂ v ,
            add <$=> invTree ♯r₁ <*=> invTree ♯r₂ <*=> invTree v
          sur (sub ♯r₁ ♯r₂ v) = T₃ 1 ♯r₁ ♯r₂ v ,
            sub <$=> invTree ♯r₁ <*=> invTree ♯r₂ <*=> invTree v
          sur (salloc n) = T₁ 2 n , salloc <$=> invTree n
          sur (sfree n) = T₁ 3 n , sfree <$=> invTree n
          sur (sld ♯r i) = T₂ 4 ♯r i , sld <$=> invTree ♯r <*=> invTree i
          sur (sst i ♯r) = T₂ 5 i ♯r , sst <$=> invTree i <*=> invTree ♯r
          sur (ld ♯r₁ ♯r₂ i) = T₃ 6 ♯r₁ ♯r₂ i ,
            ld <$=> invTree ♯r₁ <*=> invTree ♯r₂ <*=> invTree i
          sur (st ♯r₁ i ♯r₂) = T₃ 7 ♯r₁ i ♯r₂ ,
            st <$=> invTree ♯r₁ <*=> invTree i <*=> invTree ♯r₂
          sur (malloc ♯rd τs) = T₂ 8 ♯rd τs ,
            malloc <$=> invTree ♯rd <*=> invTree τs
          sur (mov ♯rd v) = T₂ 9 ♯rd v ,
            mov <$=> invTree ♯rd <*=> invTree v
          sur (beq ♯r v) = T₂ 10 ♯r v ,
            beq <$=> invTree ♯r <*=> invTree v

  InstructionSequenceₕ-Tree : ToTree H.InstructionSequence
  InstructionSequenceₕ-Tree = tree⋆ from sur
    where from : Tree → Maybe H.InstructionSequence
          from (node 0 (ι ∷ I ∷ _)) = _~>_ <$> fromTree ι <*> from I
          from (node 1 (v ∷ _)) = jmp <$> fromTree v
          from (node 2 _) = just halt
          from _ = nothing
          sur : IsSurjective from
          sur (ι ~> I) = T₂ 0 ι (proj₁ (sur I)) ,
            _~>_ <$=> invTree ι <*=> proj₂ (sur I)
          sur (jmp v) = T₁ 1 v , jmp <$=> invTree v
          sur halt = T₀ 2 , refl

  HeapValueₕ-Tree : ToTree H.HeapValue
  HeapValueₕ-Tree = tree⋆ from sur
    where from' : List Tree → Maybe (List H.WordValue)
          from' [] = just []
          from' (t ∷ ts) = _∷_ <$> fromTree t <*> from' ts
          sur' : IsSurjective from'
          sur' [] = [] , refl
          sur' (w ∷ ws) = toTree w ∷ proj₁ (sur' ws) ,
            _∷_ <$=> invTree w <*=> proj₂ (sur' ws)
          from : Tree → Maybe H.HeapValue
          from (node _ ws) = tuple <$> from' ws
          sur : IsSurjective from
          sur (tuple ws) =
            node 0 (proj₁ (sur' ws)) ,
            tuple <$=> proj₂ (sur' ws)

  GlobalValueₕ-Tree : ToTree H.GlobalValue
  GlobalValueₕ-Tree = tree⋆
    (λ { (node _ (Δ ∷ Γ ∷ I ∷ _)) →
           code[_]_∙_ <$> fromTree Δ <*> fromTree Γ <*> fromTree I
       ; _ → nothing })
    (λ { (code[ Δ ] Γ ∙ I) → T₃ 0 Δ Γ I ,
           code[_]_∙_ <$=> invTree Δ <*=> invTree Γ <*=> invTree I })

  RegisterFileₕ-Tree : ToTree H.RegisterFile
  RegisterFileₕ-Tree = tree⋆ from sur
    where from : Tree → Maybe H.RegisterFile
          from (node _ (stack ∷ regs ∷ []))
            = register <$> fromTree stack <*> fromTree regs
          from _ = nothing
          sur : IsSurjective from
          sur (register stack regs) = T₂ 0 stack regs ,
            register <$=> invTree stack <*=> invTree regs

  Programₕ-Tree : ToTree H.Program
  Programₕ-Tree = tree⋆ from sur
    where from : Tree → Maybe H.Program
          from (node 0 (G ∷ P ∷ _)) = going <$> fromTree G <*> fromTree P
          from (node 1 _) = just halted
          from _ = nothing
          sur : IsSurjective from
          sur (going G P) = T₂ 0 G P ,
            going <$=> invTree G <*=> invTree P
          sur halted = T₀ 1 , refl
