;;; SPDX-License-Identifier: PMPL-1.0-or-later
;;; BACKEND_CAPABILITIES.scm
;;; PanLL semantic/backend capability registry
;;; Draft v0.1
;;; Purpose:
;;;   Declare backend foundations, capabilities, limits, and translation policies
;;;   so PanLL can make explicit decisions about exactness, degradation, and refusal.

(backend-capabilities
  (schema-version "0.1.0")
  (registry-id "panll/backend-capabilities")
  (description
    "Registry of theorem provers, SMT solvers, description-logic reasoners, and related backends.")
  (translation-status-vocabulary
    (exact
      "Translation preserves intended semantics within the declared theory pack.")
    (conservative
      "Translation weakens or constrains the source semantics safely.")
    (heuristic
      "Translation uses search, guessing, or model assistance and requires validation.")
    (refused
      "Translation is not attempted because PanLL cannot justify it semantically."))

  (backend
    (id "rocq")
    (display-name "Rocq Prover")
    (aliases ("coq" "coq-8.x" "rocq-prover"))
    (kind theorem-prover)
    (foundation
      (family "dependent-type-theory")
      (logic "cic")
      (classical false)
      (constructive true))
    (proof-style
      (interactive true)
      (automated false)
      (certifying true))
    (supports
      (dependent-types true)
      (higher-order true)
      (first-order true)
      (induction true)
      (coinduction true)
      (typeclasses true)
      (modules true)
      (quotients limited)
      (rewriting true)
      (decision-procedures external)
      (ontology-native false))
    (quantifiers
      (forall native)
      (exists native)
      (notes "Pi-types and logical quantification may coincide or interact depending on encoding."))
    (trust-profile
      (proof-objects first-class)
      (kernel-checking true)
      (axiom-sensitivity high))
    (translation-policy
      (default-status conservative)
      (accepts-statuses (exact conservative heuristic refused))
      (never-claim-exact-for ("smt-theory-transport" "owl-dl-direct-import")))
    (interop
      (native-syntaxes ("Gallina" "Ltac"))
      (import-formats ())
      (export-formats ("sexp" "json-via-adapter"))
      (api-style ("cli" "lsp-via-wrapper")))
    (notes
      "Good target for dependent and constructive theory packs. Not a generic direct target for DL ontologies."))

  (backend
    (id "lean4")
    (display-name "Lean 4")
    (aliases ("lean" "lean-4"))
    (kind theorem-prover)
    (foundation
      (family "dependent-type-theory")
      (logic "dependent-type-theory")
      (classical configurable)
      (constructive true))
    (proof-style
      (interactive true)
      (automated mixed)
      (certifying true))
    (supports
      (dependent-types true)
      (higher-order true)
      (first-order true)
      (induction true)
      (coinduction limited)
      (typeclasses true)
      (modules true)
      (quotients true)
      (rewriting true)
      (decision-procedures external)
      (ontology-native false))
    (quantifiers
      (forall native)
      (exists native)
      (notes "Rich elaboration layer; surface syntax often hides deeper semantic choices."))
    (trust-profile
      (proof-objects first-class)
      (kernel-checking true)
      (axiom-sensitivity high))
    (translation-policy
      (default-status conservative)
      (accepts-statuses (exact conservative heuristic refused))
      (never-claim-exact-for ("owl-dl-direct-import")))
    (interop
      (native-syntaxes ("Lean"))
      (import-formats ())
      (export-formats ("json-via-adapter"))
      (api-style ("cli" "lsp")))
    (notes
      "Strong target for shared algebraic and constructive theory packs, but library-level equivalence must be declared, not assumed."))

  (backend
    (id "isabelle-hol")
    (display-name "Isabelle/HOL")
    (aliases ("isabelle" "hol"))
    (kind theorem-prover)
    (foundation
      (family "higher-order-logic")
      (logic "classical-hol")
      (classical true)
      (constructive false))
    (proof-style
      (interactive true)
      (automated mixed)
      (certifying true))
    (supports
      (dependent-types false)
      (higher-order true)
      (first-order true)
      (induction true)
      (coinduction true)
      (typeclasses limited)
      (modules theories)
      (quotients true)
      (rewriting true)
      (decision-procedures strong)
      (ontology-native false))
    (quantifiers
      (forall native)
      (exists native)
      (notes "HOL quantification is not equivalent to CIC Pi-types."))
    (trust-profile
      (proof-objects derived)
      (kernel-checking true)
      (axiom-sensitivity medium))
    (translation-policy
      (default-status conservative)
      (accepts-statuses (exact conservative heuristic refused))
      (never-claim-exact-for ("dependent-transport" "owl-dl-direct-import")))
    (interop
      (native-syntaxes ("Isar" "HOL"))
      (import-formats ())
      (export-formats ("xml" "json-via-adapter"))
      (api-style ("cli" "document-model")))
    (notes
      "Excellent target for algebraic/HOL-style packs; exactness must be theory-pack specific."))

  (backend
    (id "z3")
    (display-name "Z3")
    (aliases ("smt" "smtlib" "z3-solver"))
    (kind smt-solver)
    (foundation
      (family "first-order-with-theories")
      (logic "smt")
      (classical true)
      (constructive false))
    (proof-style
      (interactive false)
      (automated true)
      (certifying partial))
    (supports
      (dependent-types false)
      (higher-order limited)
      (first-order true)
      (induction no-native-principle)
      (coinduction false)
      (typeclasses false)
      (modules false)
      (quotients false)
      (rewriting theory-driven)
      (decision-procedures strong)
      (ontology-native false))
    (quantifiers
      (forall heuristic)
      (exists heuristic)
      (notes "Quantified reasoning is supported but not a foundation-preserving substitute for CIC/HOL proof transport."))
    (trust-profile
      (proof-objects backend-specific)
      (kernel-checking false)
      (axiom-sensitivity medium))
    (translation-policy
      (default-status conservative)
      (accepts-statuses (exact conservative heuristic refused))
      (never-claim-exact-for ("dependent-type-theory" "general-induction" "owl-dl-direct-import")))
    (interop
      (native-syntaxes ("SMT-LIB"))
      (import-formats ("smt2"))
      (export-formats ("smt2" "models" "proofs-where-available"))
      (api-style ("cli" "ffi")))
    (notes
      "Natural target for arithmetic, arrays, bitvectors, and decidable fragments. Dangerous target for pretending semantic equivalence with proof assistants."))

  (backend
    (id "elk")
    (display-name "ELK")
    (aliases ("elk-reasoner"))
    (kind dl-reasoner)
    (foundation
      (family "description-logic")
      (logic "owl-2-el")
      (classical true)
      (constructive false))
    (proof-style
      (interactive false)
      (automated true)
      (certifying limited))
    (supports
      (dependent-types false)
      (higher-order false)
      (first-order fragmentary)
      (induction false)
      (coinduction false)
      (typeclasses false)
      (modules ontologies)
      (quotients false)
      (rewriting false)
      (decision-procedures strong)
      (ontology-native true))
    (quantifiers
      (forall not-user-facing)
      (exists restricted)
      (notes "Quantification appears through DL constructors, not as general theorem-prover syntax."))
    (trust-profile
      (proof-objects limited)
      (kernel-checking false)
      (axiom-sensitivity ontology-dependent))
    (translation-policy
      (default-status exact)
      (accepts-statuses (exact conservative refused))
      (never-claim-exact-for ("general-hol-goals" "dependent-transport" "smt-theories")))
    (interop
      (native-syntaxes ("OWL 2 EL"))
      (import-formats ("owl" "rdf/xml"))
      (export-formats ("classification-results"))
      (api-style ("java" "adapter")))
    (notes
      "Best used as an ontology consistency/classification stage, not as a generic proof engine."))

  (backend
    (id "hermit")
    (display-name "HermiT")
    (aliases ("hermit-reasoner"))
    (kind dl-reasoner)
    (foundation
      (family "description-logic")
      (logic "owl-2-dl")
      (classical true)
      (constructive false))
    (proof-style
      (interactive false)
      (automated true)
      (certifying limited))
    (supports
      (dependent-types false)
      (higher-order false)
      (first-order fragmentary)
      (induction false)
      (coinduction false)
      (typeclasses false)
      (modules ontologies)
      (quotients false)
      (rewriting false)
      (decision-procedures strong)
      (ontology-native true))
    (quantifiers
      (forall not-user-facing)
      (exists restricted)
      (notes "DL reasoner semantics must not be conflated with theorem-prover quantification."))
    (trust-profile
      (proof-objects limited)
      (kernel-checking false)
      (axiom-sensitivity ontology-dependent))
    (translation-policy
      (default-status exact)
      (accepts-statuses (exact conservative refused))
      (never-claim-exact-for ("direct-cic-equivalence" "general-smt-encoding")))
    (interop
      (native-syntaxes ("OWL 2 DL"))
      (import-formats ("owl" "rdf/xml"))
      (export-formats ("classification-results" "consistency-results"))
      (api-style ("java" "adapter")))
    (notes
      "Use for ontology reasoning and extraction of justified consequences, not for pretending the ontology is already a proof assistant theory."))

  (backend
    (id "panll-slm")
    (display-name "PanLL Semantic Translator")
    (aliases ("slm" "translator"))
    (kind semantic-translator)
    (foundation
      (family "statistical-neurosymbolic")
      (logic "n/a")
      (classical unknown)
      (constructive unknown))
    (proof-style
      (interactive assistive)
      (automated generative)
      (certifying false))
    (supports
      (dependent-types text-to-text)
      (higher-order text-to-text)
      (first-order text-to-text)
      (induction suggestive)
      (coinduction suggestive)
      (typeclasses suggestive)
      (modules suggestive)
      (quotients suggestive)
      (rewriting suggestive)
      (decision-procedures none)
      (ontology-native suggestive))
    (quantifiers
      (forall surface-only)
      (exists surface-only)
      (notes "Never source of truth. Must be validated by a downstream backend."))
    (trust-profile
      (proof-objects none)
      (kernel-checking false)
      (axiom-sensitivity indirect))
    (translation-policy
      (default-status heuristic)
      (accepts-statuses (heuristic refused))
      (requires-validation-by ("rocq" "lean4" "isabelle-hol" "z3" "elk" "hermit")))
    (interop
      (native-syntaxes ("panll-universal" "backend-specific-via-prompting"))
      (import-formats ("json" "sexp" "text"))
      (export-formats ("candidate-translations"))
      (api-style ("local-model" "sidecar")))
    (notes
      "Assistant only. Never claim semantic preservation unless another backend proves it.")))
