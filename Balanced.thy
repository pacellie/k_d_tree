theory Balanced
imports
  Complex_Main
begin

type_synonym point = "real list"
type_synonym axis = nat
type_synonym dimension = nat
type_synonym disc = point

definition dim :: "point \<Rightarrow> nat"  where
  "dim p = length p"

declare dim_def[simp]

datatype kdt =
  Leaf point
| Node axis disc kdt kdt

datatype ord = LT | EQ | GT

fun cmp' :: "axis \<Rightarrow> point \<Rightarrow> point \<Rightarrow> ord" where
  "cmp' 0 p q = (
    if p!0 < q!0 then LT
    else if p!0 > q!0 then GT
    else EQ
  )"
| "cmp' a p q = (
    if p!a < q!a then LT
    else if p!a > q!a then GT
    else cmp' (a - 1) p q
  )"

fun cmp :: "axis \<Rightarrow> point \<Rightarrow> point \<Rightarrow> ord" where
  "cmp a p q = (
    if p!a < q!a then LT
    else if p!a > q!a then GT
    else cmp' (dim p - 1) p q
  )"

fun set_kdt :: "kdt \<Rightarrow> point set" where
  "set_kdt (Leaf p) = {p}"
| "set_kdt (Node _ _ l r) = set_kdt l \<union> set_kdt r"

fun size_kdt :: "kdt \<Rightarrow> nat" where
  "size_kdt (Leaf _) = 1"
| "size_kdt (Node _ _ l r) = size_kdt l + size_kdt r"

fun invar :: "dimension \<Rightarrow> kdt \<Rightarrow> bool" where
  "invar d (Leaf p) \<longleftrightarrow> dim p = d"
| "invar d (Node a disc l r) \<longleftrightarrow> (\<forall>p \<in> set_kdt l. cmp a p disc = LT \<or> cmp a p disc = EQ) \<and> (\<forall>p \<in> set_kdt r. cmp a p disc = GT) \<and>
    invar d l \<and> invar d r \<and> a < d"

lemma cmp'_EQ:
  "(\<forall>i \<le> a. p!i = q!i) \<longleftrightarrow> cmp' a p q = EQ"
  by (induction a) (auto elim: le_SucE)

lemma cmp_EQ:
  "dim p = dim q \<Longrightarrow> p = q \<longleftrightarrow> cmp a p q = EQ"
  apply (induction a)
  apply (auto)
  by (metis Suc_pred cmp'_EQ length_greater_0_conv less_Suc_eq_le nth_equalityI)+

lemma cmp'_rev:
  "cmp' a p q = GT \<Longrightarrow> cmp' a q p = LT"
  apply (induction a)
  apply (auto split: if_splits)
  done

lemma cmp'_trans:
  "dim x = d \<Longrightarrow> dim y = d \<Longrightarrow> dim z = d \<Longrightarrow> cmp' a x y = LT \<Longrightarrow> cmp' a y z = LT \<Longrightarrow> cmp' a x z = LT"
  apply (induction a)
  apply (auto split: if_splits)
  done
  
fun sorted :: "axis \<Rightarrow> point list \<Rightarrow> bool" where
  "sorted _ [] = True" 
| "sorted a (p # ps) = (
    (\<forall>q \<in> set ps. cmp a p q = LT \<or> cmp a p q = EQ) \<and> sorted a ps
  )"

fun insort :: "axis \<Rightarrow> point \<Rightarrow> point list \<Rightarrow> point list" where
  "insort _ p [] = [p]"
| "insort a p (q # ps) = (
    if cmp a p q = LT then p # q # ps
    else if cmp a p q = GT then q # insort a p ps
    else p # q # ps
  )"

definition sort :: "axis \<Rightarrow> point list \<Rightarrow> point list" where
  "sort a ps = foldr (insort a) ps []"

lemma insort_length:
  "length (insort a p ps) = length ps + 1"
  by (induction ps) auto

lemma sort_length:
  "length (sort a ps) = length ps"
  unfolding sort_def
  by (induction ps) (auto simp add: insort_length)

lemma insort_set:
  "set (insort a p ps) = {p} \<union> set ps"
  by (induction ps) auto

lemma sort_set:
  "set (sort a ps) = set ps"
  unfolding sort_def
  by (induction ps) (auto simp add: insort_set)

lemma insort_sorted:
  "dim p = d \<Longrightarrow> \<forall>p \<in> set ps. dim p = d \<Longrightarrow> sorted a ps \<Longrightarrow> sorted a (insort a p ps)"
  apply (induction ps arbitrary: a)
  apply (auto simp add: insort_set split: if_splits)
  using cmp'_rev apply blast
  apply (smt dim_def Suc_pred cmp'_EQ cmp'_trans length_greater_0_conv lessI less_Suc_eq_le nth_equalityI)
  using ord.exhaust apply blast
  by (smt Suc_pred cmp'_EQ length_greater_0_conv less_Suc_eq_le nth_equalityI ord.exhaust)

lemma sort_sorted:
  "\<forall>p \<in> set ps. dim p = d \<Longrightarrow> sorted a (sort a ps)"
  unfolding sort_def using insort_sorted sort_set sort_def
  apply (induction ps)
  apply (auto)
  done

definition split :: "axis \<Rightarrow> point list \<Rightarrow> point list * point list" where
  "split a ps = (
    let sps = sort a ps in
    let n = length ps div 2 in
    (take n sps, drop n sps)
  )"

lemma split_length:
  "split a ps = (l, g) \<Longrightarrow> length ps = length l + length g"
  unfolding split_def by (auto simp add: Let_def sort_length)

lemma aux:
  "set (take n xs) \<union> set (drop n xs) = set xs"
  by (metis append_take_drop_id set_append)

lemma split_set:
  "split a ps = (l, g) \<Longrightarrow> set ps = set l \<union> set g"
  unfolding split_def using sort_set aux[of "length ps div 2" "sort a ps"] apply (auto simp add: Let_def)
  done

lemma split_length_g_l:
  "split a ps = (l, g) \<Longrightarrow> length g \<ge> length l"
  unfolding split_def using sort_length by (auto simp add: Let_def)

lemma split_length_diff:
  "split a ps = (l, g) \<Longrightarrow> length g - length l \<le> 1"
  unfolding split_def using sort_length by (auto simp add: Let_def)

lemma split_length_eq:
  "k > 0 \<Longrightarrow> length ps = 2 ^ k \<Longrightarrow> split a ps = (l, g) \<Longrightarrow> length l = length g"
  unfolding split_def using sort_length apply (auto simp add: Let_def min_def) sorry

lemma aux2:
  "split a ps = (l, g) \<Longrightarrow> sort a ps = l @ g"
  unfolding split_def by (auto simp add: Let_def)

function (sequential) build' :: "axis \<Rightarrow> dimension \<Rightarrow> point list \<Rightarrow> kdt" where
  "build' a d ps = (
    if length ps \<le> 1 then
      Leaf (hd ps) 
    else
      let sps = sort a ps in
      let n = length sps div 2 in
      let l = take n sps in
      let g = drop n sps in
      let a' = (a + 1) mod d in
      Node a (last l) (build' a' d l) (build' a' d g)
  )"
        apply pat_completeness
       apply auto
  done
termination
  sorry


lemma aux4: 
  "length xs = 2 ^ k \<Longrightarrow> length (take (length xs div 2) xs) < length xs"
  by (metis Euclidean_Division.div_eq_0_iff div_greater_zero_iff div_less_dividend length_take min_def nat_less_le one_less_numeral_iff pos2 semiring_norm(76) zero_less_power)

lemma aux5:
  "length xs = 2 ^ k \<Longrightarrow> k > 0 \<Longrightarrow> length (take (length xs div 2) xs) = 2 ^ (k - 1)"
  by (metis aux4 length_take min_def nat_neq_iff nat_zero_less_power_iff nonzero_mult_div_cancel_right power_minus_mult zero_power2)

lemma aux6: 
  "length xs = 2 ^ k \<Longrightarrow> k > 0 \<Longrightarrow> length (drop (length xs div 2) xs) < length xs"
  by (metis Suc_leI diff_less div_2_gt_zero length_drop n_not_Suc_n nat_less_le nat_power_eq_Suc_0_iff numeral_2_eq_2 pos2 zero_less_power)

lemma aux7:
  "length xs = 2 ^ k \<Longrightarrow> length (drop (length xs div 2) xs) = 2 ^ (k - 1)"
  by (smt Euclidean_Division.div_eq_0_iff One_nat_def Suc_eq_plus1 Suc_leI add_diff_cancel_right' diff_Suc_Suc diff_is_0_eq' gr0I length_drop mult_2 nonzero_mult_div_cancel_right one_less_numeral_iff power.simps(1) power_commutes power_minus_mult rel_simps(76) semiring_norm(76))

lemma build'_set_single:
  "length ps = 1 \<Longrightarrow> set ps = set_kdt (build' a d ps)"
  apply (auto)
  apply (metis length_Suc_conv length_pos_if_in_set less_numeral_extra(3) list.sel(1) list.sel(3) list.set_cases)
  by (metis length_greater_0_conv less_Suc0 list.set_sel(1))

lemma build'_set:
  "length ps = 2 ^ k \<Longrightarrow> set ps = set_kdt (build' a d ps)"
proof (induction ps arbitrary: a k rule: length_induct)
  case (1 ps)

  let ?sps = "sort a ps"
  let ?a' = "(a + 1) mod d"

  let ?l = "take (length ?sps div 2) ?sps"
  let ?g = "drop (length ?sps div 2) ?sps"

  have L: "length ps > 1 \<longrightarrow> set ?l = set_kdt (build' ?a' d ?l)"
    using 1 sort_length aux4 aux5
    by (metis one_less_numeral_iff power_0 power_strict_increasing_iff semiring_norm(76))

  have G: "length ps > 1 \<longrightarrow> set ?g = set_kdt (build' ?a' d ?g)"
    using 1 sort_length aux6 aux7
    by (metis length_drop one_less_numeral_iff power_0 power_strict_increasing_iff semiring_norm(76))

  have "length ps > 1 \<longrightarrow> build' a d ps = Node a (last ?l) (build' ?a' d ?l) (build' ?a' d ?g)"
     by (meson build'.elims not_less)
  hence X: "length ps > 1 \<longrightarrow> set_kdt (build' a d ps) = set_kdt (build' ?a' d ?l) \<union> set_kdt (build' ?a' d ?g)"
    by simp
  have Y: "length ps > 1 \<longrightarrow> set ps = set ?l \<union> set ?g"
    by (simp add: aux sort_set)

  show ?case
  proof (cases "length ps \<le> 1")
    case True
    then show ?thesis using 1 build'_set_single
      by (simp add: le_eq_less_or_eq)
  next
    case False
    then show ?thesis using L G X Y by simp
  qed
qed

lemma insort_distinct:
  "p \<notin> set ps \<Longrightarrow> distinct ps \<Longrightarrow> distinct (insort a p ps)"
  apply (induction ps)
   apply (auto simp add: insort_set)
  done

lemma sort_distinct:
  "distinct ps \<Longrightarrow> distinct (sort a ps)"
  unfolding sort_def using sort_def insort_distinct sort_set
  apply (induction ps)
   apply auto
  done

lemma sorted_append:
  "sorted a (xs @ ys) = (sorted a xs \<and> sorted a ys \<and> (\<forall>x \<in> set xs. \<forall>y \<in> set ys. cmp a x y = LT \<or> cmp a x y = EQ))"
  apply (induction xs)
   apply (auto)
  done

lemma x:
  assumes "sorted a ps"
  shows "\<forall>x \<in> set (take n ps). \<forall>y \<in> set (drop n ps). cmp a x y = LT \<or> cmp a x y = EQ"
proof -
  obtain xs ys where 1: "ps = xs @ ys \<and> xs = take n ps \<and> ys = drop n ps"
    by fastforce
  thus ?thesis using assms sorted_append
    by metis
qed

lemma x1:
  assumes "sorted a ps"
  shows "\<forall>x \<in> set (butlast ps). cmp a x (last ps) = LT \<or> cmp a x (last ps) = EQ"
  using assms x
  by (metis append_butlast_last_id append_eq_conv_conj butlast.simps(1) length_pos_if_in_set less_numeral_extra(3) list.set_intros(1) list.size(3))

lemma butlast_last:
  "length xs \<ge> 1 \<Longrightarrow> set xs = set (butlast xs) \<union> {last xs}"
  apply (induction xs)
   apply (auto)
  using Suc_le_eq apply blast
  by (simp add: in_set_butlastD)

lemma build'_invar_single:
  "length ps = 1 \<Longrightarrow> \<forall>p \<in> set ps. dim p = d \<Longrightarrow> distinct ps \<Longrightarrow> a < d \<Longrightarrow> invar d (build' a d ps)"
  apply (auto)
  by (metis hd_in_set length_0_conv nat.distinct(1))

lemma build'_invar:
  "length ps = 2 ^ k \<Longrightarrow> \<forall>p \<in> set ps. dim p = d \<Longrightarrow> distinct ps \<Longrightarrow> a < d \<Longrightarrow> invar d (build' a d ps)"
proof (induction ps arbitrary: a k rule: length_induct)
  case (1 ps)

  let ?sps = "sort a ps"
  let ?a' = "(a + 1) mod d"
  let ?l = "take (length ?sps div 2) ?sps"
  let ?g = "drop (length ?sps div 2) ?sps"
  let ?disc = "last ?l"

  have A': "?a' < d"
    using "1.prems"(4) by auto

  have A: "\<forall>p \<in> set ?l. dim p = d"
    using "1.prems"(2) in_set_takeD sort_set by fastforce
  have B: "distinct ?l"
    using sort_distinct distinct_take
    using "1.prems"(3) by blast

  have L: "length ps > 1 \<longrightarrow> invar d (build' ?a' d ?l)"
    using 1 aux4 aux5 A B A'
    by (smt one_less_numeral_iff power_0 power_strict_increasing_iff semiring_norm(76) sort_length)

  have C: "\<forall>p \<in> set ?g. dim p = d"
    using "1.prems"(2) sort_set by (metis in_set_dropD)
  have D: "distinct ?g"
    using sort_distinct distinct_drop
    using "1.prems"(3) by blast

  have G: "length ps > 1 \<longrightarrow> invar d (build' ?a' d ?g)"
    using 1 aux6 aux7 C D A'
    by (smt less_numeral_extra(3) mod_by_1 mod_if one_mod_2_pow_eq power_0 sort_length zero_neq_one)

  have Q: "length ps > 1 \<longrightarrow> build' a d ps = Node a (last ?l) (build' ?a' d ?l) (build' ?a' d ?g)"
     by (meson build'.elims not_less)
      
  have "length ps > 1 \<longrightarrow> (\<forall>p \<in> set ?g. cmp a p ?disc = GT)"
    sorry
  hence GT: "length ps > 1 \<longrightarrow> (\<forall>p \<in> set_kdt (build' ?a' d ?g). cmp a p ?disc = GT)"
    sorry

  have "sorted a ?l"
    by (metis "1.prems"(2) Balanced.sorted_append append_take_drop_id nat_1_add_1 sort_def sort_length sort_sorted)
  hence "length ps > 1 \<longrightarrow> (\<forall>p \<in> set (butlast ?l). cmp a p ?disc = LT \<or> cmp a p ?disc = EQ)"
    using x1[of a ?l] by blast
  hence "length ps > 1 \<longrightarrow> (\<forall>p \<in> set ?l. cmp a p ?disc = LT \<or> cmp a p ?disc = EQ)"
    using butlast_last apply (auto split: if_splits)
    apply (smt One_nat_def Suc_leI UnE butlast_last empty_set insert_iff length_pos_if_in_set less_numeral_extra(3) list.size(3))
    by (smt One_nat_def Suc_leI UnE butlast_last cmp'_EQ empty_set insert_iff length_pos_if_in_set less_numeral_extra(3) list.size(3))
  hence LT: "length ps > 1 \<longrightarrow> (\<forall>p \<in> set_kdt (build' ?a' d ?l). cmp a p ?disc = LT \<or> cmp a p ?disc = EQ)"
    using Q by (smt "1.prems"(1) aux5 build'_set less_numeral_extra(3) mod_by_1 mod_if one_mod_2_pow_eq power_0 sort_length zero_neq_one)

  have QQ: "length ps > 1 \<longrightarrow> invar d (Node a (last ?l) (build' ?a' d ?l) (build' ?a' d ?g))"
    using L G LT GT 1
    using invar.simps(2) by presburger

  show ?case
  proof (cases "length ps \<le> 1")
    case True
then show ?thesis using build'_invar_single "1.prems"
  by (metis le_antisym one_le_numeral one_le_power)
next
  case False
  then show ?thesis using Q QQ
    by (metis not_less)
qed
qed

end