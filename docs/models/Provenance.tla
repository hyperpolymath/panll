--------------------------- MODULE Provenance ---------------------------
\* SPDX-License-Identifier: MPL-2.0
\*
\* Symbolic model of witnessed provenance records (EXHIBIT-B-QUANTUM-SAFE.txt,
\* docs/PROVENANCE-EXHIBIT-B.adoc). Each record is signed by its author and
\* attested by an independent witness. The claim checked here: a chain that
\* verifies is exactly the genuine chain, in order, unless BOTH the author
\* key and the witness key have leaked. One leaked key is not enough.
\*
\* PROOF-POLICY §4 exception (standards 3-practice/PROOF-POLICY.adoc). Full
\* record: PROOF-NEEDS.adoc, "Exceptions", "TLA+ model of provenance binding".
\*   Obligation: verification accepts only the genuine chain while at least
\*     one of the two signing keys is uncompromised.
\*   Tool: TLA+ / TLC. Why: a symbolic protocol statement. The shipped Rust is
\*     for Creusot/Pearlite and Verus, planned and still OPEN; this model
\*     discharges none of it.
\*   Status: TESTED (bounded: two values, chains of two), from the
\*     provenance-model job in build-validation.yml; see PROOF-NEEDS.adoc.
\*   Assumed: signatures cannot be made without the key (ML-DSA-65
\*     unforgeability), and the witness attests only genuine records.
\*
\* Configurations (all run in CI):
\*   Provenance.cfg            author key leaked   -> invariants hold
\*   ProvenanceWitnessLeak.cfg witness key leaked  -> invariants hold
\*   ProvenanceBothLeak.cfg    both keys leaked    -> Genuine MUST be violated
\* The third is the check that the property is not vacuous: with both keys,
\* a forger does get a forged chain verified, and TLC must find it.
EXTENDS Naturals, Sequences

CONSTANTS A, B, None,          \* model values
          AuthorKeyLeaked,     \* BOOLEAN
          WitnessKeyLeaked     \* BOOLEAN

Values   == {A, B}
Payloads == [field: Values, digest: Values, parent: Values \cup {None}]

\* The genuine chain: a genesis record and one record that names it.
R1 == [field |-> A, digest |-> A, parent |-> None]
R2 == [field |-> B, digest |-> B, parent |-> A]
Genuine2 == <<R1, R2>>
Intended == {R1, R2}

VARIABLES chain,          \* the records presented for verification
          content,        \* the bytes presented beside each record
          authorSigned,   \* payloads carrying an author signature
          witnessSigned,  \* payloads carrying a witness attestation
          verified        \* the verifier's last verdict on (chain, content)
vars == <<chain, content, authorSigned, witnessSigned, verified>>

TypeOK ==
  /\ chain \in Seq(Payloads) /\ Len(chain) <= 2
  /\ content \in Seq(Values) /\ Len(content) <= 2
  /\ authorSigned \subseteq Payloads
  /\ witnessSigned \subseteq Payloads
  /\ verified \in BOOLEAN

\* The honest author signed the genuine records and the witness attested
\* them; nothing else carries a signature yet.
Init ==
  /\ chain = <<>> /\ content = <<>>
  /\ authorSigned = Intended
  /\ witnessSigned = Intended
  /\ verified = FALSE

\* With a leaked key the adversary can sign any payload under it.
ForgeAuthor ==
  /\ AuthorKeyLeaked
  /\ \E p \in Payloads : authorSigned' = authorSigned \cup {p}
  /\ UNCHANGED <<chain, content, witnessSigned, verified>>

ForgeWitness ==
  /\ WitnessKeyLeaked
  /\ \E p \in Payloads : witnessSigned' = witnessSigned \cup {p}
  /\ UNCHANGED <<chain, content, authorSigned, verified>>

\* The adversary presents any two records with any content: a splice, a
\* reorder, a replay, a substituted contribution or a forgery.
Supply ==
  /\ \E r1, r2 \in Payloads, x, y \in Values :
       /\ chain' = <<r1, r2>>
       /\ content' = <<x, y>>
  /\ verified' = FALSE
  /\ UNCHANGED <<authorSigned, witnessSigned>>

\* What the verifier checks (crates/provenance verify_chain): every record
\* author-signed and witnessed, content matching its digest, and each
\* record naming its predecessor (the first naming none).
Valid ==
  /\ Len(chain) = 2 /\ Len(content) = 2
  /\ \A i \in 1..2 : /\ chain[i] \in authorSigned
                       /\ chain[i] \in witnessSigned
                       /\ chain[i].digest = content[i]
  /\ chain[1].parent = None
  /\ chain[2].parent = chain[1].field

Check ==
  /\ verified' = Valid
  /\ UNCHANGED <<chain, content, authorSigned, witnessSigned>>

Next == ForgeAuthor \/ ForgeWitness \/ Supply \/ Check
Spec == Init /\ [][Next]_vars

\* The property. It mentions the genuine chain, which the verifier never
\* sees, so it is not the definition of Valid restated: it says what Valid
\* is worth.
Genuine == verified => (chain = Genuine2 /\ content = <<R1.digest, R2.digest>>)
=============================================================================
