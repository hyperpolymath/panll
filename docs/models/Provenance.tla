--------------------------- MODULE Provenance ---------------------------
EXTENDS Naturals, Sequences, FiniteSets
\* SPDX-License-Identifier: MPL-2.0
\* Symbolic unforgeability: an attacker may change fields/content/links or
\* remove signatures, but cannot add a signature for a payload not signed.
\*
\* PROOF-POLICY §4 exception (standards 3-practice/PROOF-POLICY.adoc). Full
\* record: PROOF-NEEDS.adoc, "Exceptions", "TLA+ model of provenance binding".
\*   Obligation: a chain is verified only if each entry is author- and
\*     witness-signed over its own payload, its content matches the signed
\*     digest, and entry 2's parent names entry 1.
\*   Tool: TLA+ / TLC. Why: a symbolic protocol statement; Creusot/Pearlite
\*     and Verus check the shipped Rust, and this model discharges none of it.
\*   Status: OPEN (TLC not run in CI, no receipt). Once run: TESTED, bounds
\*     Values = {a, b}, chains of two.
\*   Limit: Binding holds by construction (Check sets verified' = Valid), and
\*     there is no forging action; see the full record.
CONSTANT Values
VARIABLES chain, authorSigned, witnessSigned, content, verified
vars == <<chain, authorSigned, witnessSigned, content, verified>>
Payloads == [field: Values, digest: Values, parent: Values]
Init == /\ chain = <<>> /\ authorSigned = {} /\ witnessSigned = {}
        /\ content = <<>> /\ verified = FALSE
Sign == \E p \in Payloads:
          /\ authorSigned' = authorSigned \cup {p}
          /\ witnessSigned' = witnessSigned \cup {p}
          /\ UNCHANGED <<chain, content, verified>>
\* Any ordered pair, including a splice or substituted contribution.
Supply == \E a,b \in Payloads, x,y \in Values:
            /\ chain' = <<a,b>> /\ content' = <<x,y>>
            /\ verified' = FALSE
            /\ UNCHANGED <<authorSigned, witnessSigned>>
Valid == /\ Len(chain) = 2
         /\ \A i \in 1..2: /\ chain[i] \in authorSigned
                             /\ chain[i] \in witnessSigned
                             /\ chain[i].digest = content[i]
         /\ chain[2].parent = chain[1].field
Check == /\ verified' = Valid
         /\ UNCHANGED <<chain, content, authorSigned, witnessSigned>>
Next == Sign \/ Supply \/ Check
Spec == Init /\ [][Next]_vars
Binding == verified => Valid
=============================================================================
