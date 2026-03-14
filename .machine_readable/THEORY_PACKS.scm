;;; SPDX-License-Identifier: PMPL-1.0-or-later
;;; THEORY_PACKS.scm
;;; PanLL semantic/theory pack registry
;;; Draft v0.1
;;; Purpose:
;;;   Make semantic intent first-class.
;;;   Surface notation is not enough; a theory pack declares meaning, laws, scope,
;;;   admissible backends, and translation expectations.

(theory-packs
  (schema-version "0.1.0")
  (registry-id "panll/theory-packs")
  (description
    "Registry of semantic packs that PanLL-Universal notation may bind to.")

  (translation-obligations
    (exact
      "Backend binding must preserve the intended semantics of the pack.")
    (conservative
      "Backend binding must explicitly record what restriction or weakening was applied.")
    (heuristic
      "Backend binding must include machine-generated provenance and downstream validation.")
    (refused
      "PanLL must not silently continue with this binding."))

  (theory-pack
    (id "core/eq/v1")
    (display-name "Core Equality")
    (kind algebraic-core)
    (status stable)
    (surface
      (preferred-notation "panll-universal")
      (symbols
        ((eq "=")
         (neq "!="))))
    (intent
      "Minimal equality vocabulary used by many other packs.")
    (semantic-contract
      (sorts (A))
      (operations
        ((eq (A A -> Prop))))
      (laws
        (reflexive)
        (symmetric)
        (transitive)
        (substitutive)))
    (scope
      (foundation-neutral true)
      (requires-classical false)
      (requires-dependent-types false))
    (bindings
      (binding
        (backend-id "rocq")
        (status exact)
        (target "eq")
        (notes "Uses backend-native equality."))
      (binding
        (backend-id "lean4")
        (status exact)
        (target "Eq")
        (notes "Uses backend-native equality."))
      (binding
        (backend-id "isabelle-hol")
        (status exact)
        (target "=")
        (notes "Uses backend-native equality."))
      (binding
        (backend-id "z3")
        (status exact)
        (target "=")
        (notes "Safe at the level of first-order/theory equality where applicable."))))

  (theory-pack
    (id "nat/peano/v1")
    (display-name "Natural Numbers (Peano/Inductive)")
    (kind arithmetic)
    (status experimental)
    (surface
      (preferred-notation "panll-universal")
      (symbols
        ((nat "N")
         (zero "0")
         (succ "S")
         (add "+")
         (mul "*"))))
    (intent
      "Inductive natural numbers with structural induction.")
    (semantic-contract
      (sorts (Nat))
      (operations
        ((zero Nat)
         (succ (Nat -> Nat))
         (add (Nat Nat -> Nat))
         (mul (Nat Nat -> Nat))))
      (laws
        (peano-zero-not-successor)
        (peano-successor-injective)
        (induction-principle)
        (add-zero-right-identity)
        (add-successor-recursion)))
    (scope
      (foundation-neutral false)
      (requires-classical false)
      (requires-dependent-types false)
      (notes
        "Pack is mathematically ordinary but tied to inductive natural number semantics, not arbitrary integers."))
    (bindings
      (binding
        (backend-id "rocq")
        (status exact)
        (target "nat")
        (notes "Backend-native inductive naturals."))
      (binding
        (backend-id "lean4")
        (status exact)
        (target "Nat")
        (notes "Backend-native naturals."))
      (binding
        (backend-id "isabelle-hol")
        (status conservative)
        (target "nat")
        (notes "Good fit, but proof and library transport must be theory-aware, not assumed identical."))
      (binding
        (backend-id "z3")
        (status conservative)
        (target "Int with n >= 0 discipline")
        (losses
          (no-native-structural-induction)
          (non-canonical-model-behaviour-under-quantifiers))
        (notes "Allowed only when the goal falls in an explicitly approved arithmetic fragment."))
      (binding
        (backend-id "elk")
        (status refused)
        (notes "DL reasoner; not an arithmetic prover."))))

  (theory-pack
    (id "algebra/additive-monoid/v1")
    (display-name "Additive Monoid")
    (kind algebraic-structure)
    (status stable)
    (surface
      (preferred-notation "panll-universal")
      (symbols
        ((carrier "A")
         (zero "0")
         (add "+"))))
    (intent
      "Common algebraic structure for safe cross-backend transport.")
    (semantic-contract
      (sorts (A))
      (operations
        ((zero A)
         (add (A A -> A))))
      (laws
        (associative add)
        (left-identity zero add)
        (right-identity zero add)))
    (scope
      (foundation-neutral true)
      (requires-classical false)
      (requires-dependent-types false))
    (bindings
      (binding
        (backend-id "rocq")
        (status exact)
        (target "typeclass or record encoding"))
      (binding
        (backend-id "lean4")
        (status exact)
        (target "typeclass encoding"))
      (binding
        (backend-id "isabelle-hol")
        (status exact)
        (target "locale/type-class style encoding"))
      (binding
        (backend-id "z3")
        (status conservative)
        (target "uninterpreted sort + function + axioms")
        (notes "Useful for bounded obligation discharge, but not equivalent to proof-assistant algebra libraries."))))

  (theory-pack
    (id "logic/first-order/v1")
    (display-name "First-Order Logic Core")
    (kind logic-core)
    (status stable)
    (surface
      (preferred-notation "panll-universal")
      (symbols
        ((forall "forall")
         (exists "exists")
         (imp "->")
         (and "/\\")
         (or "\\/")
         (not "~"))))
    (intent
      "Portable core for first-order reasoning.")
    (semantic-contract
      (sorts (Prop Term Sort))
      (operations
        ((forall ((Sort (Term -> Prop)) -> Prop))
         (exists ((Sort (Term -> Prop)) -> Prop))))
      (laws
        (beta-like-binding-discipline)
        (capture-avoidance)
        (standard-connective-laws)))
    (scope
      (foundation-neutral partially)
      (requires-classical configurable)
      (requires-dependent-types false)
      (notes
        "Portable as a core notation layer, but backend proof principles vary sharply."))
    (bindings
      (binding
        (backend-id "rocq")
        (status conservative)
        (target "Prop-level quantification")
        (notes "Exact only inside explicitly non-dependent fragments."))
      (binding
        (backend-id "lean4")
        (status conservative)
        (target "Prop-level quantification")
        (notes "Exact only inside explicitly non-dependent fragments."))
      (binding
        (backend-id "isabelle-hol")
        (status exact)
        (target "HOL FOL-style fragment"))
      (binding
        (backend-id "z3")
        (status exact)
        (target "SMT-LIB first-order core")
        (notes "Subject to backend quantifier behaviour and supported theories."))))

  (theory-pack
    (id "ontology/owl2-el/classification/v1")
    (display-name "OWL 2 EL Classification")
    (kind ontology)
    (status experimental)
    (surface
      (preferred-notation "ontology-graph")
      (symbols
        ((subclass "subclass-of")
         (equiv "equiv")
         (exists "exists")
         (top "top")
         (bottom "bottom"))))
    (intent
      "Use ontology reasoning to validate class hierarchy and extract safe consequences.")
    (semantic-contract
      (sorts (Class Role Individual))
      (operations
        ((subclass (Class Class -> Prop))
         (equiv (Class Class -> Prop))
         (exists-restriction (Role Class -> Class))))
      (laws
        (owl2-el-profile-discipline)
        (classification-soundness)))
    (scope
      (foundation-neutral false)
      (requires-classical true)
      (requires-dependent-types false)
      (notes
        "Not a generic theorem-proving pack. Intended for ontology classification and fact extraction."))
    (bindings
      (binding
        (backend-id "elk")
        (status exact)
        (target "OWL 2 EL ontology"))
      (binding
        (backend-id "hermit")
        (status conservative)
        (target "OWL 2 DL ontology")
        (notes "Allowed if source ontology remains within the declared EL-safe fragment for this pack."))
      (binding
        (backend-id "rocq")
        (status conservative)
        (target "fact import only")
        (losses
          (reasoner-externality)
          (no-direct-ontology-semantics))
        (notes "Only classified consequences may be imported, each with provenance."))
      (binding
        (backend-id "lean4")
        (status conservative)
        (target "fact import only"))
      (binding
        (backend-id "z3")
        (status refused)
        (notes "Not a direct ontology target for this pack."))))

  (theory-pack
    (id "bridge/ontology-facts/v1")
    (display-name "Ontology Consequence Import")
    (kind bridge-pack)
    (status experimental)
    (surface
      (preferred-notation "panll-universal")
      (symbols
        ((fact "fact")
         (source "from"))))
    (intent
      "Bridge pack for importing externally justified ontology consequences into proof contexts.")
    (semantic-contract
      (sorts (OntologyFact Provenance))
      (operations
        ((assert-fact (OntologyFact Provenance -> Prop))))
      (laws
        (every-fact-has-provenance)
        (every-fact-records-source-backend)
        (every-fact-records-profile)
        (bridge-is-not-semantic-equivalence)))
    (scope
      (foundation-neutral partially)
      (requires-classical configurable)
      (requires-dependent-types false)
      (notes
        "This is the safe bridge. It imports justified consequences, not the entire ontology semantics."))
    (bindings
      (binding
        (backend-id "rocq")
        (status conservative)
        (target "axiom/fact context with provenance wrapper"))
      (binding
        (backend-id "lean4")
        (status conservative)
        (target "fact context with provenance wrapper"))
      (binding
        (backend-id "isabelle-hol")
        (status conservative)
        (target "fact context with provenance wrapper"))
      (binding
        (backend-id "z3")
        (status conservative)
        (target "assertion context with provenance sidecar")))))
