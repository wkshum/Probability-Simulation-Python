import Mathlib.Tactic
import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Log.NegMulLog

/-

Objectives:

* We define Shannon entropy for finite and discrete probability distribution. Expectations are finite sums
and hence measure theory is avoided. (A full-blown formulation of entropy was done in the project of
polynomial Friemann-Ruzsa conjecture.)

* A discrete distribution is defined as a nonnegative real-valued function on a finite sample space, so that
the sum of all components is equal to 1. If the probabilities are p_i, for i ranging over the sample space,
the Shannon entropy is defined as the sum of - p_i log p_i. When p_i =0, the value of p_i log p_i is
defined as 0.

The function -x log x is implemented by negMulLog, which has just been introduced in Mathlib.

* The main result is the proof of the inequality that entropy is bounded between 0 and log(K), where K is the
cardinality of the sample space. This is split into two theorems:

theorem entropy_ge_zero

theorem entropy_le_log_suppsize



Natural log is employed throughout. The unit of entropy is nat.

-/


noncomputable section


namespace entropy


open Real BigOperators

/-
  Assume all probability distibutions are defined over a finite alphabet
-/
variable {α : Type*} [DecidableEq α] [Fintype α]
variable {β  : Type*} [DecidableEq β] [Fintype β]


/-
 Data structure for discrete probability disribution

 a probabilty disribution function P is the function called dist
    bundled with two additional conditions.

  We make a term with type Discreteist α acting like a function by making it FunLike.

-/

@[ext]
structure DiscreteDist (α : Type*) [Fintype α] where
  dist : α → ℝ
  NonNeg : ∀ i : α ,  dist i ≥ 0
  sum_eq_one : ∑ i : α , dist i = 1

instance instFunLike : FunLike (DiscreteDist α) α ℝ  where
  coe p a := (p.dist a)
  coe_injective' p q h := by
    ext a
    have h1 : (fun p a ↦ p.dist a) p = p.dist := by rfl
    have h2 : (fun p a ↦ p.dist a) q = q.dist := by rfl
    rw [h1, h2] at h
    exact congrFun h a


theorem prob_sum_to_one (P: DiscreteDist α ): ∑ x:α , P x = 1 := P.sum_eq_one





/-
 Shannon entropy and mutual information  for finite distribution
-/

-- Shannon entropy is a function of a discrete pobability distribution
-- The function negMulLog  f(x) = -x log x
--   is defined as 0 when x = 0


def H (f : DiscreteDist α) : ℝ :=
  ∑ i : α , negMulLog (f i)


-- Binary entropy function
def h_b (p:ℝ) : ℝ := negMulLog p + negMulLog (1-p)




----------------------------------------

/-
Example of probability distribution
-/



/-
  Example: Uniform distribution on {0,1,2,...,n-1}
-/
def uniform_dist (n:ℕ) (hpos: n> 0) : DiscreteDist (Fin n) where
  dist := λ (i : Fin n) => 1/(n:ℝ)
  NonNeg := by
    simp
  sum_eq_one := by
    have h2: n ≠ 0 := by exact Nat.pos_iff_ne_zero.mp hpos
    norm_num
    refine mul_inv_cancel ?_
    exact Nat.cast_ne_zero.mpr h2


/-
 Example: Uniform distribution on a finite set
-/
def uniform_dist'  (hnz : Fintype.card α ≠ 0) : DiscreteDist α where
  dist := λ (i : α) => 1/(Fintype.card α)
  NonNeg := by simp
  sum_eq_one := by
    simp
    refine mul_inv_cancel ?_
    exact Nat.cast_ne_zero.mpr hnz



/-
Discrete probability distribution has values less than or equal to 1
-/
theorem prob_le_one (f : DiscreteDist α ) :   ∀ j : α , f j ≤ 1 := by
  intro j
  let g (j i : α ) : ℝ  := if i=j then (f j) else 0
  have h₀ : ∀ i : α  , g j i ≤ f i := by
    intro i
    by_cases h2 : i=j
    · simp [h2]
    · simp [h2]
      exact f.NonNeg i


  calc
    f j = ∑ i , g j i := by simp [Finset.sum_mul]
        _ ≤  ∑ i , f i  :=  Finset.sum_le_sum fun i _ ↦ h₀ i
        _ = 1 := f.sum_eq_one


-- Example: uniform distribution over a product of two finite sets
def dist_mn (m n : ℕ ) (hm: m > 0) (hn: n> 0): DiscreteDist (Fin m × Fin n) where
  dist := λ (_i : Fin m × Fin n) => (m*n : ℝ )⁻¹
  NonNeg := by
    intro i
    simp
    have h₁ : (m:ℝ)⁻¹ ≥ 0 := inv_nonneg.mpr (le_of_lt (Nat.cast_pos.mpr hm))
    have h₂ : (n:ℝ)⁻¹ ≥ 0 := inv_nonneg.mpr (le_of_lt (Nat.cast_pos.mpr hn))
    exact mul_nonneg h₂ h₁
  sum_eq_one := by
    dsimp
    simp
    have h₁ : Finset.univ.card = (Fintype.card (Fin m × Fin n)) := by rfl
    rw [h₁]
    rw [Fintype.card_prod (Fin m) (Fin n) ]
    rw [Fintype.card_fin m, Fintype.card_fin n]
    simp
    calc
      (m:ℝ) * (n:ℝ) * ((n:ℝ )⁻¹ * (m:ℝ )⁻¹)
         = (m:ℝ)* (m:ℝ )⁻¹ * (n:ℝ) * (n:ℝ )⁻¹ := by ring
       _ = 1 * (n:ℝ) * (n:ℝ )⁻¹ := by rw [mul_inv_cancel (Nat.cast_ne_zero.mpr (Nat.pos_iff_ne_zero.mp hm))]
       _ = (n:ℝ) * (n:ℝ)⁻¹ := by ring
       _ =  1 := by rw [mul_inv_cancel (Nat.cast_ne_zero.mpr (Nat.pos_iff_ne_zero.mp hn))]



----------------------------------------------------------






/-

 Useful lemmas about summation

-/

-- Split the domain of summation into two disjoint parts
lemma split_summation_domain (F : α → ℝ )  (p : α → Prop )  [DecidablePred p] :
   ∑ i:α , F i = (∑ i: {i: α // ¬ p i } , F i) + (∑ i: {i: α // p i } , F i)  := by

  have h_comp : Set.toFinset {x | ¬p x} = (Set.toFinset {x | p x})ᶜ := by
    ext x
    rw [Set.mem_toFinset, Finset.mem_compl, Set.mem_toFinset]
    trivial
  rw [← Finset.sum_toFinset_eq_subtype (fun i:α => (p i)) _]
  rw [← Finset.sum_toFinset_eq_subtype (fun i:α => (¬ p i)) _]
  rw [h_comp]
  rw [Finset.sum_compl_add_sum (Set.toFinset {x | p x}) F]



-- We can ignore some zero terms when computing a finite sum

lemma sum_eq_sum_nz_term (F G : α → ℝ ) (h : ∀ x: α , G x =0 → F x = 0):
        ∑ i:α , F i  = (∑ i: {i: α // G i ≠ 0 } , F i) := by
  have h₀ : ∑ i: {i: α // G i = 0 } , F i = 0 := by
    rw [← Finset.sum_toFinset_eq_subtype (fun i:α => (G i = 0)) F]
    refine Finset.sum_eq_zero ?h
    intro x hx
    have h': x ∈ {x | G x = 0} := Set.mem_toFinset.mp hx
    exact h x h'
  rw [split_summation_domain F (fun i:α => (G i = 0))]
  conv =>
    lhs
    congr
    rfl
    rw [h₀]
  ring


-- It suffices to sum over the nonzero terms when computing a finite sum

lemma sum_eq_sum_over_support (F: α → ℝ ):
        ∑ i:α , F i  = (∑ i: {i: α // F i ≠ 0 } , F i) := by
  refine sum_eq_sum_nz_term F F ?_
  intro x hx
  exact hx


-- In the definition of entropy we can only sum over outcomes that have positive probabilities.

theorem entropy_sum_over_support (f: DiscreteDist α) :
      H f = ∑ i : {i : α // f i ≠ 0} , Real.negMulLog (f i) := by
  simp [H]
  refine sum_eq_sum_nz_term (fun i:α => Real.negMulLog (f i)) (f)  ?_

  -- using the lemma sum_eq_sum_nz_term,
  -- it suffices to prove that f.dist x = 0 implies negMulLog (f.dist x) = 0
  intro x hx
  dsimp
  rw [hx]
  exact Real.negMulLog_zero



/-
The basic inequality in information theory:    log x ≤  x-1 for positive x
-/
example (x:ℝ) (hpos : x > 0) : Real.log x ≤ x - 1 :=
  Real.log_le_sub_one_of_pos hpos




/-
Lower and upper bound on Shannon entopy
-/

-- Entropy is nonnegative
theorem entropy_ge_zero (f : DiscreteDist α) : (H f) ≥ 0 := by
  have h1 :  ∀ i : α , f i ≤ 1 := prob_le_one f  -- The value of f i is probability
  dsimp [H, Real.negMulLog]
  simp [Finset.sum_mul]
  apply Finset.sum_nonpos
  intro i
  have h2 : f i ≥ 0 := f.NonNeg i
  simp [Real.mul_log_nonpos (h2) (h1 i)]





-- If random variable X takes at most K values, then  H(X) ≤ log K

/- Sketch of proof:
  H(X) - log(K)
= ∑_{i} P(i) log P(i) - ∑_{i} p(i)*log(K)             (Step 1)
= ∑_{i} P(i) log (1/ (K*log P(i)))                    (Step 2)
≤ ∑_{i} P(i) [1/(K*log P(i)) - 1]                     (Step 3)
= 0                                                   (Step 4)

-/
theorem entropy_le_log_suppsize  (hpos : (Fintype.card α)> 0) (f : DiscreteDist α) :
          (H f) ≤ Real.log (Fintype.card α) := by

  let K := Fintype.card α   -- cardinary of alphabet size = K
  have hKnez :  (K:ℝ) ≠ 0 := by   -- K as a real number is not equal to 0
    refine Nat.cast_ne_zero.mpr ?_
    apply ne_of_gt
    calc
        0 < Fintype.card α := by rel [hpos]
        _ = K := rfl

  have h₀ :  ∑ i : {i:α // f i ≠ 0}  , (f i) = 1 := by
    rw [← sum_eq_sum_over_support f]
    rw [prob_sum_to_one f]

  have h₁ : Real.log K = ∑ i : {i // f i ≠ 0}, f i * Real.log K := by
    have h₂ := by
      exact Finset.sum_toFinset_eq_subtype (fun i:α => (f i ≠ 0)) (fun i:α => (f i)*(Real.log K))
    have h₃ := by
      exact Finset.sum_toFinset_eq_subtype (fun i:α => (f i ≠ 0)) (fun i:α => (f i))
    rw [← Finset.sum_mul, h₃, h₀] at h₂
    simp at h₂
    exact h₂

  -- Step 1
  apply sub_nonpos.mp  -- It suffices to show   H f - Real.log K ≤ 0
  rw [entropy_sum_over_support f, h₁]
  rw [← Finset.sum_sub_distrib]

  -- Step 2
  have h₄ : ∑ i : { i : α // f i ≠ 0 }, (Real.negMulLog (f i) - f i * Real.log K)
      = ∑ i : {i // f i ≠ 0} , (f i) * (Real.log ((f i)* K)⁻¹)  := by
    refine Fintype.sum_congr _ _ ?_
    simp only [Subtype.forall]
    intro i hi
    have h₅ : Real.negMulLog (f i) = -(f i)*Real.log (f i) := by rfl
    rw [h₅]
    calc
      -f i * Real.log (f i) - f i * (Real.log K)
            = - (f i) * (Real.log (f i) +  Real.log K) := by ring
          _ = - (f i) * (Real.log ((f i)* K)) := by rw [Real.log_mul hi hKnez]
          _ = (f i) * (- Real.log ((f i)* K)) := by ring
          _ = (f i) * (Real.log ((f i)* K)⁻¹) := by rw [Real.log_inv]
  rw [h₄]

  -- Step 3: The main step that utilizes the concaviy of the log function
  have h₆ : ∑ i : {i:α // f i ≠ 0}, (f i) * (Real.log ((f i)* K)⁻¹)
     ≤  ∑ i : {i:α // f i ≠ 0} , (f i)* (((f i)*(K:ℝ))⁻¹ - 1) := by
    refine Finset.sum_le_sum ?_
    simp only [Subtype.forall]
    intro x hx _

    have hf_nng : 0 ≤ f x := f.NonNeg x  -- f x is larger than or equal 0
    have hf_pos : 0 < f x  := by exact Ne.lt_of_le (Ne.symm hx) hf_nng
    have hpos1 : 0< (f x * ↑(Fintype.card α))⁻¹ := by
      refine inv_pos.mpr ?_
      exact Real.mul_pos hf_pos (Nat.cast_pos.mpr hpos)
    have basic_inequality :
       (Real.log (f x * ↑(Fintype.card α))⁻¹ ) ≤ (((f x * ↑(Fintype.card α))⁻¹ - 1)) := by
      exact Real.log_le_sub_one_of_pos hpos1
    exact (mul_le_mul_left hf_pos).mpr basic_inequality

  have h₇ : ∑ i : {i:α // f i ≠ 0} , (f i)* (((f i)*(K:ℝ))⁻¹ - 1)
     ≤  ∑ i : α  , ((K:ℝ)⁻¹ - f i ) := by
    have h₇' : ∑ i : α,  (f i)* (((f i)*(K:ℝ))⁻¹ - 1)
        = ∑ i : {i:α // f i ≠ 0} , (f i)* (((f i)*(K:ℝ))⁻¹ - 1) := by
      refine sum_eq_sum_nz_term _ (fun i:α => f i) ?_
      intro x hx
      simp at hx
      rw [hx]
      norm_num
    rw [← h₇']
    refine Finset.sum_le_sum ?_

    intro x _
    by_cases hf_zero : f x = 0
    · rw [hf_zero]
      simp
    · have h₇'': f x * ((f x * ↑K)⁻¹ - 1) = (↑K)⁻¹  - f x := by
        calc
          f x * ((f x * ↑K)⁻¹ - 1)
            =  f x * (f x)⁻¹ * (↑K)⁻¹  - f x := by ring
          _ = 1*(↑K)⁻¹  - f x := by rw [mul_inv_cancel hf_zero]
          _ = (↑K)⁻¹  - f x := by ring
      exact Eq.le h₇''

  have h₈  : ∑ i : α , ((K:ℝ)⁻¹ - f i ) = 0 := by
    have h₉ : ∑ _a : α , (K:ℝ)⁻¹ = 1 := by
      simp
      refine mul_inv_cancel ?_
      exact Nat.cast_ne_zero.mpr (Nat.pos_iff_ne_zero.mp hpos)

    rw [Finset.sum_sub_distrib]
    rw [prob_sum_to_one f, h₉]
    ring

  exact ge_trans (ge_trans (Eq.le h₈) h₇) h₆

  done










-------------------------------------------------

/-
The rest of the file is junkyark
-/


/-
  Samples low-level functions used in the proof
-/

-- #check Subtype.forall

-- #check Finset.sum_toFinset_eq_subtype

-- #check Finset.sum_sub_distrib

-- #check Finset.sum_mul

-- #check Finset.sum_toFinset_eq_subtype

-- #check Equiv.subtypeEquivRight

-- #check Finset.sum_union

-- #check Finset.sum_compl_add_sum s f
/-

-- x*log x is defined as 0 when x=0
example {x : ℝ} (h : x =0) : Real.negMulLog x = 0 := by
  rw [h]
  exact Real.negMulLog_zero

example {x:ℝ}  : Real.negMulLog x = -x * Real.log x := rfl

theorem nonneg  (f: α → ℝ)  (h: ∀ i : α  , f i ≥ 0 ):
  ∑ i, f i ≥ 0 := by
    calc
      ∑ i, f i ≥ ∑ i, 0 := by exact Finset.sum_le_sum fun i _ ↦ h i
      _ = 0 := by exact Fintype.sum_eq_zero (fun _ ↦ 0) (congrFun rfl)

theorem nonpos  (f: α → ℝ)  (h: ∀ i : α  , f i ≤  0 ):
  ∑ i, f i ≤  0 := by
    calc
      ∑ i, f i ≤  ∑ i, 0 := by exact Finset.sum_le_sum fun i _ ↦ h i
      _ = 0 := by exact Fintype.sum_eq_zero (fun _ ↦ 0) (congrFun rfl)

theorem monotone  (f: α → ℝ) (g: α → ℝ) (h: ∀ i : α  , f i ≤ g i ):
  ∑ i, f i ≤  ∑ i , g i := by
   exact Finset.sum_le_sum fun i _ ↦ h i

theorem additive  (f: α → ℝ) (g: α → ℝ) (_: α → ℝ) :
  ∑ i, (f i + g i) = ∑ i, f i + ∑ i , g i := by exact Finset.sum_add_distrib

example  (f: α → ℝ) (g: α → ℝ)(h: ∀ i : α  , f i = g i ) : ∑ i, f i =  ∑ i , g i := by
 exact Fintype.sum_congr f g h

example (h: n = Fintype.card α) :  n = ∑ i:α , 1  :=
  calc
   n = Fintype.card α := by rw [h]
   _ = ∑ i:α , 1 := by exact Fintype.card_eq_sum_ones


example (hn : n = Fintype.card α) (hnz : Fintype.card α ≠ 0) : ∑ i : α , (1/(n:ℝ)) = 1 := by
  simp
  rw [hn]
  exact mul_inv_cancel (Nat.cast_ne_zero.mpr hnz)

-/

/-

An unnecessarily complicated proof
lemma split_summation_domain' (F : α → ℝ)  (p : α → Prop )  [DecidablePred p] :
    ∑ i:α , F i  =  (∑ i: {i: α // ¬ p i } , F i) + (∑ i: {i: α // p i } , F i)  := by

  have h₀ :  ∀ i:α , (ite (¬ p i) (F i) 0) + (ite (p i) (F i) 0) = F i:= by
    intro i
    by_cases h : p i
    repeat simp [h]
  have h₁ : (∑ i: {i: α // p i } , F i) = (∑ i , ite (p i) (F i) 0) := by
    rw [← Finset.sum_toFinset_eq_subtype (fun i:α => (p i)) F]
    rw [← Fintype.sum_extend_by_zero]
    refine Fintype.sum_congr _ _ ?_
    intro x
    simp only [Set.mem_toFinset]
    simp
  have h₂ : (∑ i: {i: α // ¬ p i } , F i) = (∑ i , ite (¬ p i) (F i) 0) := by
    rw [← Finset.sum_toFinset_eq_subtype (fun i:α => (¬ p i)) F]
    rw [← Fintype.sum_extend_by_zero]
    refine Fintype.sum_congr _ _ ?_
    intro x
    simp only [Set.mem_toFinset]
    simp
  rw [← Fintype.sum_congr (fun i:α=> (ite (¬ p i) (F i) 0) + (ite (p i) (F i) 0)) F h₀]
  rw [Finset.sum_add_distrib]
  rw [h₁, h₂]


example (m:ℕ ) (h: m≠ 0) : (m:ℝ) ≠ 0 := by exact Nat.cast_ne_zero.mpr h

example (m:ℕ) (h: m> 0) : m ≠ 0 := by exact Nat.pos_iff_ne_zero.mp h

example (a:ℝ) (h: a≠ 0) : a*a⁻¹ = 1:= by exact mul_inv_cancel h

example (β : Type*) [Fintype β] : Fintype.card (α × β) = (Fintype.card α)*(Fintype.card β) := by
  exact Fintype.card_prod α β

example (m : ℕ ): Fintype.card (Fin m) = m := by exact Fintype.card_fin m

example (a b : ℕ ) : (a*b :ℝ) = (a:ℝ) *(b:ℝ) := by exact rfl

example (a b:ℝ ) : a⁻¹ * b⁻¹ = (a*b)⁻¹ := by exact (mul_inv a b).symm

example (a : ℝ ) (h: a > 0) : a ≥ 0 := by exact le_of_lt h

example (a: ℕ ) (h: a> 0) : (a:ℝ ) > 0 := by exact Nat.cast_pos.mpr h

example (a:ℝ ) (h :a ≥ 0) : a⁻¹ ≥ 0 := by exact inv_nonneg.mpr h
-/



def H_joint (f : DiscreteDist (α × β)) : ℝ :=
  ∑ i : (α × β), negMulLog (f.dist i)




end entropy
