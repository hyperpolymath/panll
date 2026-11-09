--------------------------- MODULE Provenance ---------------------------
\* SPDX-License-Identifier: MPL-2.0
\*
\* PROOF-POLICY section 4 exception record (standards 3-practice/PROOF-POLICY.adoc).
\* Obligation: an attacker who can supply any chain with any content bytes,
\*   attach any published signature, and sign with the author's key once it
\*   leaks, cannot obtain a "verified" verdict for a record the author did not
\*   intend, or for a chain whose links or content do not match. The
\*   independent witness required by docs/PROVENANCE-EXHIBIT-B.adoc is what
\*   carries this after an author-key compromise.
\* Tool: TLA+ checked by TLC, a finite model check. Status: TESTED with the
\*   bounds in Provenance.cfg, never PROVEN.
\* Why not the mapped verifiers: the property concerns an adversary
\*   interleaving with honest parties, which pre/postconditions on
\*   verify_chain do not state. The implementation obligations stay OPEN for
\*   Creusot/Pearlite and Verus in PROOF-NEEDS.adoc.
\* Trust boundary: signatures and hashes are perfectly binding (symbolic
\*   model); a record's hash is the record itself. Not a cryptographic proof,
\*   not an implementation-correspondence proof. Author and witness keys
\*   are not both compromised.
\*
\* Checked both ways:
\*   Provenance.cfg            RequireWitness = TRUE:  Unforgeable, Linked hold.
\*   ProvenanceNoWitness.cfg   RequireWitness = FALSE: Unforgeable must FAIL
\*                             (author-key forgery), so the witness check is
\*                             load-bearing and the invariant is not vacuous.
\*   ProvenanceReachable.cfg   NeverVerified must FAIL: verified states exist.
EXTENDS Naturals, Sequences

CONSTANTS Digests,          \* content digests (finite set of model values)
          None,             \* model value: "no parent"
          RequireWitness    \* does the verifier demand a witness attestation?

ASSUME None \notin Digests /\ RequireWitness \in BOOLEAN

Roots    == [digest: Digests, parent: {None}]
\* A child names its parent by the parent's hash. A root's hash is
\* determined by its digest (its parent is fixed), so at this depth the
\* parent link is the root's digest.
Children == [digest: Digests, parent: Digests]
Records  == Roots \cup Children

VARIABLES intended,     \* records the honest author chose to publish
          authorSigs,   \* records carrying a valid author signature
          witnessSigs,  \* records carrying a valid witness attestation
          compromised,  \* has the author's private key leaked?
          chain,        \* the chain a verifier is handed
          content,      \* the content bytes (as digests) handed with it
          verified      \* the verifier's verdict on (chain, content)
vars == <<intended, authorSigs, witnessSigs, compromised, chain, content, verified>>

Init == /\ intended = {} /\ authorSigs = {} /\ witnessSigs = {}
        /\ compromised = FALSE /\ chain = <<>> /\ content = <<>>
        /\ verified = FALSE

\* The honest author signs a record it intends.
AuthorSigns == \E r \in Records:
                 /\ intended' = intended \cup {r}
                 /\ authorSigs' = authorSigs \cup {r}
                 /\ UNCHANGED <<witnessSigs, compromised, chain, content, verified>>

\* The honest, independent witness attests only records the author intended.
WitnessAttests == \E r \in intended:
                    /\ witnessSigs' = witnessSigs \cup {r}
                    /\ UNCHANGED <<intended, authorSigs, compromised, chain, content, verified>>

\* The author's key leaks.
Compromise == /\ ~compromised
              /\ compromised' = TRUE
              /\ UNCHANGED <<intended, authorSigs, witnessSigs, chain, content, verified>>

\* After the leak the attacker signs anything with the author's key.
ForgeAuthor == /\ compromised
               /\ \E r \in Records: authorSigs' = authorSigs \cup {r}
               /\ UNCHANGED <<intended, witnessSigs, compromised, chain, content, verified>>

\* The attacker hands over any chain of one or two records with any content:
\* reordered, spliced, truncated or substituted. Signatures are public, so
\* every existing one is available to attach.
Supply == /\ \E n \in 1..2:
               \E s \in [1..n -> Records], c \in [1..n -> Digests]:
                 /\ chain' = s
                 /\ content' = c
          /\ verified' = FALSE
          /\ UNCHANGED <<intended, authorSigs, witnessSigs, compromised>>

LinkOK(i) == IF i = 1 THEN chain[1].parent = None
                      ELSE /\ chain[i - 1].parent = None
                           /\ chain[i].parent = chain[i - 1].digest

\* What verify_chain accepts as "verified" (all entries).
Valid == /\ Len(chain) \in 1..2
         /\ \A i \in 1..Len(chain):
              /\ chain[i] \in authorSigs
              /\ RequireWitness => chain[i] \in witnessSigs
              /\ chain[i].digest = content[i]
              /\ LinkOK(i)

Check == /\ verified' = Valid
         /\ UNCHANGED <<intended, authorSigs, witnessSigs, compromised, chain, content>>

Next == AuthorSigns \/ WitnessAttests \/ Compromise \/ ForgeAuthor \/ Supply \/ Check
Spec == Init /\ [][Next]_vars

TypeOK == /\ intended \subseteq Records /\ authorSigs \subseteq Records
          /\ witnessSigs \subseteq intended /\ compromised \in BOOLEAN
          /\ verified \in BOOLEAN

\* A verified chain contains only records the author intended, each matching
\* the content it was handed.
Unforgeable == verified => \A i \in 1..Len(chain):
                             /\ chain[i] \in intended
                             /\ chain[i].digest = content[i]

\* A verified chain starts at a root and every link names its predecessor.
Linked == verified => \A i \in 1..Len(chain): LinkOK(i)

\* Expected to FAIL (ProvenanceReachable.cfg): a verified state is reachable.
NeverVerified == ~verified
=============================================================================
