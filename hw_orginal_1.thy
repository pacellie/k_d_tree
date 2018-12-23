theory hw_orginal_1
imports
  Complex_Main
begin

type_synonym point = "real list"
type_synonym axis = nat
type_synonym dimension = nat
type_synonym split = real

definition dim :: "point \<Rightarrow> nat"  where
  "dim p = length p"

definition incr :: "axis \<Rightarrow> dimension \<Rightarrow> axis" where
  "incr a d = (a + 1) mod d"

declare dim_def[simp]
declare incr_def[simp]

datatype kdt =
  Leaf point
| Node kdt split kdt

fun set_kdt :: "kdt \<Rightarrow> point set" where
  "set_kdt (Leaf p) = {p}"
| "set_kdt (Node l _ r) = set_kdt l \<union> set_kdt r"

fun invar' :: "axis \<Rightarrow> dimension \<Rightarrow> kdt \<Rightarrow> bool" where
  "invar' _ k (Leaf p) \<longleftrightarrow> k > 0 \<and> dim p = k"
| "invar' a k (Node l s r) \<longleftrightarrow> (\<forall>p \<in> set_kdt l. p!a \<le> s) \<and> (\<forall>p \<in> set_kdt r. p!a > s) \<and>
    invar' (incr a k) k l \<and> invar' (incr a k) k r"

lemma invar'_l_r:
  assumes "invar' a k (Node l s r)"
  shows "invar' (incr a k) k l \<and> invar' (incr a k) k r"
  using assms
  by simp

lemma set_kdt_dim:
  assumes "invar' a k kdt"
  shows "\<forall>p \<in> set_kdt kdt. dim p = k"
  using assms
  by (induction kdt arbitrary: a) auto

lemma set_kdt_l_lq_a: 
  assumes "invar' a k kdt" "kdt = Node l s r"
  shows "\<forall>p \<in> set_kdt l. p!a \<le> s"
  using assms by (induction kdt arbitrary: a) auto

lemma set_kdt_r_gt_a: 
  assumes "invar' a k kdt" "kdt = Node l s r"
  shows "\<forall>p \<in> set_kdt r. s < p!a"
  using assms by (induction kdt arbitrary: a) auto

definition squared_distance' :: "real \<Rightarrow> real \<Rightarrow> real" where
  "squared_distance' x y = (x - y) ^ 2"

lemma squared_distance'_ge_0:
  "squared_distance' x y \<ge> 0"
  using squared_distance'_def by simp

lemma squared_distance'_eq_0[simp]:
  "squared_distance' x y = 0 \<longleftrightarrow> x = y"
  using squared_distance'_def by simp

lemma squared_distance'_com:
  "squared_distance' x y = squared_distance' y x"
  using squared_distance'_def by (simp add: power2_commute)

lemma X:
  assumes "x \<le> 0" "y \<le> 0"
  shows "x\<^sup>2 + y\<^sup>2 \<le> ((x::real) + y)\<^sup>2"
proof -
  have "x\<^sup>2 + y\<^sup>2 \<le> x\<^sup>2 + 2 * x * y + y\<^sup>2"
    using assms by (simp add: zero_le_mult_iff)
  also have "... = (x + y)\<^sup>2"
    by algebra
  finally show ?thesis .
qed

lemma squared_distance'_split:
  assumes "x \<le> s" "s \<le> y"
  shows "squared_distance' x y \<ge> squared_distance' x s + squared_distance' s y"
  unfolding squared_distance'_def using X assms by smt

fun squared_distance :: "point \<Rightarrow> point \<Rightarrow> real" where
  "squared_distance [] [] = 0"
| "squared_distance (x # xs) (y # ys) = squared_distance' x y + squared_distance xs ys"
| "squared_distance _ _ = undefined"

lemma squared_distance_ge_0:
  assumes "dim p\<^sub>0 = dim p\<^sub>1"
  shows "squared_distance p\<^sub>0 p\<^sub>1 \<ge> 0"
  using assms
  by (induction p\<^sub>0 p\<^sub>1 rule: squared_distance.induct) (auto simp add: squared_distance'_ge_0)

lemma squared_distance_eq_0[simp]:
  assumes "p\<^sub>0 = p\<^sub>1"
  shows "squared_distance p\<^sub>0 p\<^sub>1 = 0"
  using assms 
  by(induction p\<^sub>0 p\<^sub>1 rule: squared_distance.induct) auto

lemma squared_distance_com:
  assumes "dim p\<^sub>0 = dim p\<^sub>1"
  shows "squared_distance p\<^sub>0 p\<^sub>1 = squared_distance p\<^sub>1 p\<^sub>0"
  using assms
  by (induction p\<^sub>0 p\<^sub>1 rule: squared_distance.induct) (auto simp add: squared_distance'_com)

lemma squared_distance_update:
  assumes "dim p\<^sub>0 = k" "dim p\<^sub>1 = k" "a < k"
  shows "squared_distance p\<^sub>0 p\<^sub>1 \<ge> squared_distance p\<^sub>0 (p\<^sub>0[a := (p\<^sub>1!a)])"
  using assms
  apply (induction p\<^sub>0 p\<^sub>1 arbitrary: a k rule: squared_distance.induct)
  apply (auto simp add: squared_distance'_ge_0 squared_distance_ge_0 split: nat.splits)
  by (metis add_mono squared_distance'_eq_0 squared_distance'_ge_0)

lemma aux:
  assumes "dim p\<^sub>0 = k" "dim p\<^sub>1 = k" "a < k"
  shows "squared_distance p\<^sub>0 (p\<^sub>0[a := (p\<^sub>1!a)]) \<ge> squared_distance' (p\<^sub>0!a) (p\<^sub>0[a := (p\<^sub>1!a)]!a)"
  using assms
  apply (induction p\<^sub>0 p\<^sub>1 arbitrary: a k rule: squared_distance.induct)
  by (auto simp add: squared_distance'_def split: nat.splits)

definition min_by_squared_distance :: "point \<Rightarrow> point \<Rightarrow> point \<Rightarrow> point" where
  "min_by_squared_distance p\<^sub>0 p\<^sub>1 q = (
    if squared_distance p\<^sub>0 q \<le> squared_distance p\<^sub>1 q then p\<^sub>0 else p\<^sub>1
  )"

fun nearest_neighbor' :: "axis \<Rightarrow> dimension \<Rightarrow> point \<Rightarrow> kdt \<Rightarrow> point" where
  "nearest_neighbor' _ _ _ (Leaf p) = p"
| "nearest_neighbor' a k p (Node l s r) = (
    if p!a \<le> s then
      let candidate = nearest_neighbor' (incr a k) k p l in
      if squared_distance p candidate \<le> squared_distance' s (p!a) then
        candidate
      else
        let candidate' = nearest_neighbor' (incr a k) k p r in
        min_by_squared_distance candidate candidate' p
    else
      let candidate = nearest_neighbor' (incr a k) k p r in
      if squared_distance p candidate < squared_distance' s (p!a) then
        candidate
      else
        let candidate' = nearest_neighbor' (incr a k) k p l in
        min_by_squared_distance candidate candidate' p
  )"

lemma nearest_neighbor'_in_kdt:
  assumes "invar' a k kdt" "dim p = k"
  shows "nearest_neighbor' a k p kdt \<in> set_kdt kdt"
  using assms
  by (induction kdt arbitrary: a) (auto simp add: Let_def min_by_squared_distance_def)

lemma aux0:
  assumes "invar' a k (Node l s r)" "p!a \<le> s" "c \<in> set_kdt l" "dim p = k" "a < k"
  assumes "squared_distance p c \<le> squared_distance' s (p!a)"
  shows "\<forall>q \<in> set_kdt r. squared_distance p c \<le> squared_distance p q"
proof standard
  fix q
  assume A: "q \<in> set_kdt r"

  let ?q' = "p[a := (q!a)]"

  have "squared_distance p q \<ge> squared_distance p ?q'"
    using A assms(1,4,5) invar'_l_r set_kdt_dim squared_distance_update by blast
  hence "squared_distance p q \<ge> squared_distance' (p!a) (?q'!a)"
    by (smt A assms(1,4,5) aux invar'_l_r set_kdt_dim)
  hence "squared_distance p q \<ge> squared_distance' (p!a) s + squared_distance' s (q!a)"
    by (smt A assms(1,2,4,5) dim_def nth_list_update_eq set_kdt_r_gt_a squared_distance'_split)
  hence "squared_distance p q \<ge> squared_distance' s (p!a)"
    by (smt squared_distance'_com squared_distance'_ge_0)
  hence "squared_distance p q \<ge> squared_distance p c"
    using assms(6) by linarith
  thus "squared_distance p c \<le> squared_distance p q" by blast
qed

lemma aux00:
  assumes "invar' a k (Node l s r)" "p!a > s" "c \<in> set_kdt r" "dim p = k" "a < k"
  assumes "squared_distance p c < squared_distance' s (p!a)"
  shows "\<forall>q \<in> set_kdt l. squared_distance p c \<le> squared_distance p q"
proof standard
  fix q
  assume A: "q \<in> set_kdt l"

  let ?q' = "p[a := (q!a)]"

  have "squared_distance p q \<ge> squared_distance p ?q'"
    using A assms(1,4,5) invar'_l_r set_kdt_dim squared_distance_update by blast
  hence "squared_distance p q \<ge> squared_distance' (p!a) (?q'!a)"
    by (smt A assms(1,4,5) aux invar'_l_r set_kdt_dim)
  hence "squared_distance p q \<ge> squared_distance' (p!a) s + squared_distance' s (q!a)"
    by (smt A assms(1,2,4,5) dim_def nth_list_update_eq set_kdt_l_lq_a squared_distance'_com squared_distance'_split)
  hence "squared_distance p q \<ge> squared_distance' s (p!a)"
    by (smt squared_distance'_com squared_distance'_ge_0)
  hence "squared_distance p q \<ge> squared_distance p c"
    using assms(6) by linarith
  thus "squared_distance p c \<le> squared_distance p q" by blast
qed

lemma nearest_neighbor'_optimum:
  assumes "invar' a k kdt" "dim p = k" "a < k"
  shows "\<forall>q \<in> set_kdt kdt. squared_distance (nearest_neighbor' a k p kdt) p \<le> squared_distance q p"
  using assms
proof (induction kdt arbitrary: a)
  case (Leaf p)
  thus ?case by simp                                      
next
  case (Node l s r)
  consider (A) "p!a \<le> s" | (B) "p!a > s"
    by fastforce
  thus ?case
  proof cases
    case A
    let ?candidate = "nearest_neighbor' (incr a k) k p l"
    show ?thesis
    proof (cases "squared_distance p ?candidate \<le> squared_distance' s (p!a)")
      case True
      hence CUTOFF: "\<forall>q \<in> set_kdt r. squared_distance p ?candidate \<le> squared_distance p q"
        using A Node.prems(1,3) assms(2) aux0 invar'_l_r nearest_neighbor'_in_kdt by blast

      have IH1: "\<forall>q \<in> set_kdt l. squared_distance ?candidate p \<le> squared_distance q p"
        using Node.IH(1) Node.prems(1,3) assms(2) by auto

      have "squared_distance (nearest_neighbor' a k p (Node l s r)) p = squared_distance ?candidate p"
        using A True by auto
      thus ?thesis using A True IH1
        apply (auto)
        by (smt CUTOFF Node.prems(1) assms(2) invar'_l_r nearest_neighbor'_in_kdt set_kdt_dim squared_distance_com)
    next
      case False
      thus ?thesis using Node A min_by_squared_distance_def
        apply (auto)
        by (smt Suc_lessI mod_less mod_less_divisor zero_less_Suc)+
    qed
  next
    case B
    let ?candidate = "nearest_neighbor' (incr a k) k p r"
    show ?thesis
    proof (cases "squared_distance p ?candidate < squared_distance' s (p!a)")
      case True
      hence CUTOFF: "\<forall>q \<in> set_kdt l. squared_distance ?candidate p \<le> squared_distance q p"
        by (smt B Node.prems(1,3) assms(2) aux00 invar'_l_r nearest_neighbor'_in_kdt set_kdt_dim squared_distance_com)

      have IH2: "\<forall>q \<in> set_kdt r. squared_distance ?candidate p \<le> squared_distance q p"
        using Node.IH(2) Node.prems(1) assms(2,3) by auto

      have "squared_distance (nearest_neighbor' a k p (Node l s r)) p = squared_distance ?candidate p"
        using B True by auto
      thus ?thesis using B True IH2
        apply (auto)
        by (metis CUTOFF Suc_eq_plus1 incr_def)
    next
      case False
      thus ?thesis using Node B min_by_squared_distance_def
        apply (auto)
        by (smt Suc_lessI mod_less mod_less_divisor zero_less_Suc)+
    qed
  qed
qed

theorem nearest_neighbor':
  assumes "invar' a k kdt" "dim p = k" "a < k"
  shows "(\<forall>q \<in> set_kdt kdt. squared_distance (nearest_neighbor' a k p kdt) p \<le> squared_distance q p) \<and> nearest_neighbor' a k p kdt \<in> set_kdt kdt"
  using assms nearest_neighbor'_in_kdt nearest_neighbor'_optimum by simp

end