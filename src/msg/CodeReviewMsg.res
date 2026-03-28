// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code Review messages -- PR review, inline comments, approval gates.

open Model

type codeReviewMsg =
  | SetCrTab(codeReviewTab)
  | SetCrFilter(string)
  | SelectPr(string)
  | ApprovePr
  | DismissCrError
