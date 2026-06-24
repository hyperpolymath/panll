// SPDX-License-Identifier: MPL-2.0

/// Code Review messages -- PR review, inline comments, approval gates.

open Model

type codeReviewMsg =
  | SetCrTab(codeReviewTab)
  | SetCrFilter(string)
  | SelectPr(string)
  | ApprovePr
  | DismissCrError
