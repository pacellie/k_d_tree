theory Submission_FDS
imports
  Complex_Main
  "HOL-Library.Tree"
begin

text \<open>
  A k-d tree is a space-partitioning data structure for organizing points in a k-dimensional space.
  In principle the k-d tree is a binary tree in which every node is a k-dimensional point.
  Every node divides the space into two parts by splitting along a hyperplane.
  Consider a node n with associated point p in depth d, counting the number of edges from the root.
  The splitting hyperplane of this point will be the (d mod k) axis of the associated point p.
  Let v be the value of p at axis (d mod k). Subsequently all points in the left subtree must have
  a value at axis (d mod k) that is less or equal than v and all points in the right subtree must
  have a value at axis (d mod k) that is greater than v.

  e.g.: Consider a 2-d tree.

   0/x-axis:                      (7, 2)

   1/y-axis:           (5,4)               (9,6)

   0/x-axis:    (2,3)        (4,7)                (8,7)
\<close>

text \<open>Synonyms for point, axis, dimension and k-d tree.\<close>

type_synonym point = "real list"
type_synonym axis = nat
type_synonym dim = nat
type_synonym kdt = "point tree"

text \<open>
  First Part:

  Defining the invariant, abstraction and defining insertion into a k-d tree and membership of
  a k-d tree.
\<close>

text \<open>Abstraction function relating k-d tree to set:\<close>

fun set_kdt :: "kdt \<Rightarrow> point set" where
  "set_kdt Leaf = {}"
| "set_kdt (Node l p r) = {p} \<union> set_kdt l \<union> set_kdt r"

text \<open>The k-d tree invariant:\<close>

fun invar' :: "axis \<Rightarrow> dim \<Rightarrow> kdt \<Rightarrow> bool" where
  "invar' _ k Leaf \<longleftrightarrow> k > 0"
| "invar' a k (Node l p r) \<longleftrightarrow> invar' ((a+1) mod k) k l \<and> invar' ((a+1) mod k) k r \<and>
    length p = k \<and> (\<forall>q \<in> set_kdt l. q!a \<le> p!a) \<and> (\<forall>q \<in> set_kdt r. q!a \<ge> p!a)"

text \<open>Insertion:\<close>

fun ins_kdt' :: "axis \<Rightarrow> dim \<Rightarrow> point \<Rightarrow> kdt \<Rightarrow> kdt" where
  "ins_kdt' _ _ p Leaf = Node Leaf p Leaf"
| "ins_kdt' a k p (Node l x r) = (
    if p = x then Node l x r
    else
      if p!a \<le> x!a then
        Node (ins_kdt' ((a+1) mod k) k p l) x r
      else
        Node l x (ins_kdt' ((a+1) mod k) k p r)
  )"

text \<open>Membership:\<close>

fun isin_kdt' :: "axis \<Rightarrow> dim \<Rightarrow> point \<Rightarrow> kdt \<Rightarrow> bool" where
  "isin_kdt' _ _ _ Leaf = False"
| "isin_kdt' a k p (Node l x r) = (
    if p = x then True
    else
      if p!a \<le> x!a then
        isin_kdt' ((a+1) mod k) k p l
      else
        isin_kdt' ((a+1) mod k) k p r
  )"

text \<open>Lemmas about Insertion and Membership:\<close>

lemma set_ins_kdt': "invar' a k kdt \<Longrightarrow> length p = k \<Longrightarrow> set_kdt (ins_kdt' a k p kdt) = set_kdt kdt \<union> {p}"
  by (induction kdt arbitrary: a) auto

lemma invar_ins_kdt': "invar' a k kdt \<Longrightarrow> length p = k \<Longrightarrow> invar' a k (ins_kdt' a k p kdt)"
  by (induction kdt arbitrary: a) (auto simp add: set_ins_kdt')

lemma isin_kdt': "invar' a k kdt \<Longrightarrow> length p = k \<Longrightarrow> isin_kdt' a k p kdt \<longleftrightarrow> p \<in> set_kdt kdt"
  by (induction kdt arbitrary: a) auto

text \<open>
  I would like to drop explicitly passing the splitting axis into every function.
  Define abbreviations and start splitting at 0th axis.
  The corresponding Insertion and Membership functions and lemmas in shorter form:
\<close>

abbreviation invar where "invar \<equiv> invar' 0"

definition ins_kdt :: "point \<Rightarrow> kdt \<Rightarrow> kdt" where
  "ins_kdt p = ins_kdt' 0 (length p) p"

definition isin_kdt :: "point \<Rightarrow> kdt \<Rightarrow> bool" where
  "isin_kdt p = isin_kdt' 0 (length p) p"

lemma set_ins_kdt: "invar k kdt \<Longrightarrow> length p = k \<Longrightarrow> set_kdt (ins_kdt p kdt) = set_kdt kdt \<union> {p}"
  by (simp add: ins_kdt_def set_ins_kdt')

lemma invar_ins_kdt: "invar k kdt \<Longrightarrow> length p = k \<Longrightarrow> invar k (ins_kdt p kdt)"
  by (simp add: ins_kdt_def invar_ins_kdt')

lemma isin_kdt: "invar k kdt \<Longrightarrow> length p = k \<Longrightarrow> isin_kdt p kdt \<longleftrightarrow> p \<in> set_kdt kdt"
  by (simp add: isin_kdt' isin_kdt_def)

text \<open>
  Second Part:

  Verifying k-dimensional queries on the k-d tree.

  Given two k-dimensional points p1 and p2 which bound the search space, the query should return
  only the points which satisfy the following criteria:

  For every point x in the resulting set:
    For every axis a \<in> [0, k-1]:
      min (p1!a) (p2!a) <= x!a and x!a <= max (p1!a) (p2!a)

  For example: In a 2-d tree a query corresponds to selecting all the points in
  the rectangle which has p1 and p2 as its defining edges.
\<close>

text \<open>
  Simplifying the problem:

  Assume that the two given points p1 and p2  which define the bounding box are the left lower
  and the right upper point.

  For every axis a \<in> [0, k-1]:
    p1!a <= p2!a
\<close>

text\<open>The query function and auxiliary functions:\<close>

definition is_bounding_box :: "dim \<Rightarrow> point \<Rightarrow> point \<Rightarrow> bool" where
  "is_bounding_box k b u \<longleftrightarrow> length b = k \<and> length u = k \<and> (\<forall>i < k. b!i \<le> u!i)"

(* I don't want to unfold this definition in the main function *)
definition point_in_bounding_box :: "dim \<Rightarrow> point \<Rightarrow> point \<Rightarrow> point \<Rightarrow> bool" where
  "point_in_bounding_box k p b u \<longleftrightarrow> (\<forall>i < k. b!i \<le> p!i \<and> p!i \<le> u!i)"

fun query_area' :: "axis \<Rightarrow> dim \<Rightarrow> point \<Rightarrow> point \<Rightarrow> kdt \<Rightarrow> point set" where
  "query_area' _ _ _ _ Leaf = {}"
| "query_area' a k b u (Node l p r) = (
    if point_in_bounding_box k p b u then
      {p} \<union> query_area' ((a+1) mod k) k b u l \<union> query_area' ((a+1) mod k) k b u r
    else
      if p!a < b!a then
        query_area' ((a+1) mod k) k b u r
      else if p!a > u!a then
        query_area' ((a+1) mod k) k b u l
      else
        query_area' ((a+1) mod k) k b u l \<union> query_area' ((a+1) mod k) k b u r
  )"

text \<open>Auxiliary lemmas:\<close>

lemma set_kdt_l_lq_a: "invar' a k kdt \<Longrightarrow> kdt = Node l x r \<Longrightarrow> \<forall>p \<in> set_kdt l. p!a \<le> x!a"
  by (induction kdt arbitrary: a) auto

lemma set_kdt_r_gt_a: "invar' a k kdt \<Longrightarrow> kdt = Node l x r \<Longrightarrow> \<forall>p \<in> set_kdt r. x!a < p!a"
  by (induction kdt arbitrary: a) auto

lemma invar'_dim_gt_0: "invar' a k kdt \<Longrightarrow> k > 0"
  by (induction kdt arbitrary: a) auto

lemma l_pibb_empty:
  assumes "invar' a k kdt" "kdt = Node l x r" "is_bounding_box k b u" "x!a < b!a" "a < k"
  shows "{ p \<in> set_kdt l. point_in_bounding_box k p b u } = {}"
  using assms
proof -
  have "\<forall>p \<in> set_kdt l. p!a \<le> x!a"
    using set_kdt_l_lq_a assms(1) assms(2) by blast
  then have "\<forall>p \<in> set_kdt l. p!a < b!a"
    using assms(4) by auto
  then have "\<forall>p \<in> set_kdt l. (\<exists>i < k. p!i < b!i \<or> u!i < p!i)"
    using assms(5) by blast
  then have "\<forall>p \<in> set_kdt l. \<not>point_in_bounding_box k p b u"
    using point_in_bounding_box_def by fastforce
  then show ?thesis by blast
qed

lemma r_pibb_empty:
  assumes "invar' a k kdt" "kdt = Node l x r" "is_bounding_box k b u" "x!a > u!a" "a < k"
  shows "{ p \<in> set_kdt r. point_in_bounding_box k p b u } = {}"
  using assms
proof -
  have "\<forall>p \<in> set_kdt r. x!a < p!a"
    using set_kdt_r_gt_a assms(1) assms(2) by blast
  then have "\<forall>p \<in> set_kdt r. u!a < p!a"
    using assms(4) by auto
  then have "\<forall>p \<in> set_kdt r. (\<exists>i < k. p!i < b!i \<or> u!i < p!i)"
    using assms(5) by blast
  then have "\<forall>p \<in> set_kdt r. \<not>point_in_bounding_box k p b u"
   using point_in_bounding_box_def by fastforce
  then show ?thesis by blast
qed

text \<open>The main theorem:\<close>

theorem query_area':
  assumes "invar' a k kdt" "is_bounding_box k b u" "a < k"
  shows "query_area' a k b u kdt = { p \<in> set_kdt kdt. point_in_bounding_box k p b u }"
  using assms l_pibb_empty r_pibb_empty
  by (induction kdt arbitrary: a) auto

text \<open>
  Again I would like to drop explicitly passing the splitting axis into every function.
  The corresponding query function and lemmas in shorter form:
\<close>

definition query_area :: "point \<Rightarrow> point \<Rightarrow> kdt \<Rightarrow> point set" where
  "query_area b u kdt = query_area' 0 (length b) b u kdt"

theorem query_area:
  assumes "invar k kdt" "is_bounding_box k b u"
  shows "query_area b u kdt = { p \<in> set_kdt kdt. point_in_bounding_box k p b u }"
  using assms invar'_dim_gt_0 is_bounding_box_def query_area' query_area_def by auto

text \<open>
  Finally un-simplifying the problem:

  Given two arbitrary points p1 and p2 which only satisfy the dimensionality property,
  does the query function work?

  Hide the is_bounding_box abstraction:
\<close>

text \<open>Auxiliary functions and the final query function:\<close>

fun min_max :: "real * real \<Rightarrow> real * real" where
  "min_max (a, b) = (min a b, max a b)"

definition to_bounding_box :: "point \<Rightarrow> point \<Rightarrow> point * point" where
  "to_bounding_box p q = (let ivs = map min_max (zip p q) in (map fst ivs, map snd ivs))"

definition query :: "point \<Rightarrow> point \<Rightarrow> kdt \<Rightarrow> point set" where
  "query p q kdt = (let (b, u) = to_bounding_box p q in query_area b u kdt)"

text \<open>Auxiliary lemmas and the final theorem:\<close>

lemma tbbibb:
  assumes "k = length p" "k = length q" "(b,u) = to_bounding_box p q"
  shows "is_bounding_box k b u"
  using assms by (auto simp add: to_bounding_box_def is_bounding_box_def)

lemma pibb_p_q:
  assumes "k = length p" "k = length q" "(b, u) = to_bounding_box p q"
  shows "point_in_bounding_box k x b u \<longleftrightarrow> (\<forall>i < k. min (p!i) (q!i) \<le> x!i \<and> x!i \<le> max (p!i) (q!i))"
  using assms by (auto simp add: min_def max_def to_bounding_box_def point_in_bounding_box_def)

theorem query:
  assumes "invar k kdt" "k = length p" "k = length q"
  shows "query p q kdt = { x \<in> set_kdt kdt. \<forall>i < k. min (p!i) (q!i) \<le> x!i \<and> x!i \<le> max (p!i) (q!i) }"
  using assms pibb_p_q tbbibb query_area by (auto simp add: query_def)

end
