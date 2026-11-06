--------------------------- MODULE Provenance ---------------------------
EXTENDS Naturals, Sequences, FiniteSets
\* SPDX-License-Identifier: MPL-2.0
\* Symbolic unforgeability: an attacker may change fields/content/links or
\* remove signatures, but cannot add a signature for a payload not signed.
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
