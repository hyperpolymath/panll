;;; SPDX-License-Identifier: PMPL-1.0-or-later
;;; TRANSLATION_STATUS.scm
;;; PanLL translation honesty vocabulary
;;; Draft v0.1

(translation-statuses
  (schema-version "0.1.0")

  (status
    (id exact)
    (display-name "Exact")
    (ui-color "green")
    (definition
      "PanLL has a declared semantic pack and a backend binding that preserves the intended meaning within that pack.")
    (required-evidence
      (theory-pack-id)
      (backend-id)
      (binding-proof-or-policy))
    (user-message
      "This target preserves the declared semantics for this pack."))

  (status
    (id conservative)
    (display-name "Conservative")
    (ui-color "blue")
    (definition
      "PanLL has translated safely by restricting or weakening the original semantics.")
    (required-evidence
      (theory-pack-id)
      (backend-id)
      (declared-losses))
    (user-message
      "This target is safe to use, but it is not semantically identical; some meaning has been restricted."))

  (status
    (id heuristic)
    (display-name "Heuristic")
    (ui-color "amber")
    (definition
      "PanLL has used search, inference, or model assistance to propose a translation that must be validated downstream.")
    (required-evidence
      (generator-id)
      (validation-target))
    (user-message
      "This translation is a candidate, not a trusted equivalence. Validation is required."))

  (status
    (id refused)
    (display-name "Refused")
    (ui-color "red")
    (definition
      "PanLL will not translate because it cannot justify the semantics.")
    (required-evidence
      (reason-code))
    (user-message
      "PanLL refused to translate this because it cannot do so honestly.")))
