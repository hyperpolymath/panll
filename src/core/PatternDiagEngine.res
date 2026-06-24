// SPDX-License-Identifier: MPL-2.0

/// Code MRI — Pattern Diagnostics Engine (Layer 3)
///
/// Pure computation for detecting code evolution patterns and managing
/// developer gamification. Takes timeline snapshots (Layer 2) and provenance
/// data (Layer 1) as inputs, produces pattern instances and XP awards.
///
/// All functions are pure — no side effects, no Gossamer invocations.

open PatternDiagModel

// ===========================================================================
// Pattern Detection
// ===========================================================================

/// Detect hotspot churn: same file appearing in N consecutive fix commits.
/// Returns pattern instances for files modified in 3+ consecutive snapshots.
let detectHotspotChurn = (
  snapshots: array<TimelineEngine.timelineSnapshot>,
  _threshold: int,
): array<patternInstance> => {
  // With fewer than 3 snapshots, no churn detection is meaningful.
  if Array.length(snapshots) < 3 {
    []
  } else {
    // Placeholder: actual implementation reads commit-level file lists from
    // VeriSimDB. The engine produces the types; the command layer queries.
    []
  }
}

/// Detect TODO creep: TODO count growing for more than N consecutive snapshots.
let detectTodoCreep = (
  snapshots: array<TimelineEngine.timelineSnapshot>,
  windowSize: int,
): array<patternInstance> => {
  let len = Array.length(snapshots)
  if len < windowSize {
    []
  } else {
    let recent = snapshots->Array.slice(~start=len - windowSize, ~end=len)
    let isCreeping = recent->Array.reduceWithIndex(true, (acc, snap, i) => {
      if i == 0 {
        acc
      } else {
        switch recent->Array.get(i - 1) {
        | Some(prev) => acc && snap.todoCount > prev.todoCount
        | None => acc
        }
      }
    })
    if isCreeping {
      [
        {
          id: "todo-creep-" ++ (recent->Array.get(len - 1)->Option.map(s => s.commitHash)->Option.getOr("unknown")),
          kind: TodoCreep,
          severity: Warning,
          description: `TODO count has grown for ${Int.toString(windowSize)} consecutive snapshots`,
          files: [],
          detectedAt: recent->Array.get(Array.length(recent) - 1)->Option.map(s => s.timestamp)->Option.getOr(""),
          commitRange: switch (recent->Array.get(0), recent->Array.get(Array.length(recent) - 1)) {
          | (Some(first), Some(last)) => Some((first.commitHash, last.commitHash))
          | _ => None
          },
          acknowledged: false,
        },
      ]
    } else {
      []
    }
  }
}

/// Detect unreviewed AI growth: AI attribution rising without review.
let detectUnreviewedAiGrowth = (
  snapshots: array<TimelineEngine.timelineSnapshot>,
  threshold: float,
): array<patternInstance> => {
  let len = Array.length(snapshots)
  if len < 2 {
    []
  } else {
    switch (snapshots->Array.get(0), snapshots->Array.get(len - 1)) {
    | (Some(oldest), Some(newest)) =>
      let growth = newest.aiAttributionPercent -. oldest.aiAttributionPercent
      if growth > threshold {
        [
          {
            id: "unreviewed-ai-" ++ newest.commitHash,
            kind: UnreviewedAiGrowth,
            severity: Advisory,
            description: `AI attribution grew by ${Float.toFixed(growth, ~digits=1)}% over ${Int.toString(len)} snapshots`,
            files: [],
            detectedAt: newest.timestamp,
            commitRange: Some((oldest.commitHash, newest.commitHash)),
            acknowledged: false,
          },
        ]
      } else {
        []
      }
    | _ => []
    }
  }
}

/// Detect sustained friction: vexometer above threshold for N snapshots.
let detectSustainedFriction = (
  snapshots: array<TimelineEngine.timelineSnapshot>,
  threshold: float,
  windowSize: int,
): array<patternInstance> => {
  let len = Array.length(snapshots)
  if len < windowSize {
    []
  } else {
    let recent = snapshots->Array.slice(~start=len - windowSize, ~end=len)
    let allAbove = recent->Array.every(s => s.vexometerReading > threshold)
    if allAbove {
      [
        {
          id: "sustained-friction-" ++ Float.toString(Date.now()),
          kind: SustainedFriction,
          severity: Warning,
          description: `Vexometer above ${Float.toFixed(threshold, ~digits=0)} for ${Int.toString(windowSize)} consecutive snapshots`,
          files: [],
          detectedAt: recent->Array.get(Array.length(recent) - 1)->Option.map(s => s.timestamp)->Option.getOr(""),
          commitRange: None,
          acknowledged: false,
        },
      ]
    } else {
      []
    }
  }
}

/// Detect positive patterns: TODO reduction, findings reduction, type cleanup.
let detectPositivePatterns = (
  snapshots: array<TimelineEngine.timelineSnapshot>,
): array<patternInstance> => {
  let len = Array.length(snapshots)
  if len < 2 {
    []
  } else {
    let results = []
    switch (snapshots->Array.get(len - 2), snapshots->Array.get(len - 1)) {
    | (Some(prev), Some(curr)) => {
        let acc = ref(results)
        if curr.todoCount < prev.todoCount {
          acc :=
            Array.concat(
              acc.contents,
              [
                {
                  id: "todo-reduction-" ++ curr.commitHash,
                  kind: TodoReduction,
                  severity: Celebration,
                  description: `Closed ${Int.toString(prev.todoCount - curr.todoCount)} TODOs`,
                  files: [],
                  detectedAt: curr.timestamp,
                  commitRange: Some((prev.commitHash, curr.commitHash)),
                  acknowledged: false,
                },
              ],
            )
        }
        if curr.panicAttackFindings < prev.panicAttackFindings {
          acc :=
            Array.concat(
              acc.contents,
              [
                {
                  id: "findings-reduction-" ++ curr.commitHash,
                  kind: FindingsReduction,
                  severity: Celebration,
                  description: `Resolved ${Int.toString(prev.panicAttackFindings - curr.panicAttackFindings)} security findings`,
                  files: [],
                  detectedAt: curr.timestamp,
                  commitRange: Some((prev.commitHash, curr.commitHash)),
                  acknowledged: false,
                },
              ],
            )
        }
        if curr.failedTypeChecks < prev.failedTypeChecks {
          acc :=
            Array.concat(
              acc.contents,
              [
                {
                  id: "typecheck-cleanup-" ++ curr.commitHash,
                  kind: TypeCheckCleanup,
                  severity: Celebration,
                  description: `Fixed ${Int.toString(prev.failedTypeChecks - curr.failedTypeChecks)} type check failures`,
                  files: [],
                  detectedAt: curr.timestamp,
                  commitRange: Some((prev.commitHash, curr.commitHash)),
                  acknowledged: false,
                },
              ],
            )
        }
        acc.contents
      }
    | _ => []
    }
  }
}

/// Run all pattern detectors against the timeline and return merged results.
let analyseTimeline = (
  snapshots: array<TimelineEngine.timelineSnapshot>,
): array<patternInstance> => {
  Array.concat(
    Array.concat(
      Array.concat(
        detectHotspotChurn(snapshots, 3),
        detectTodoCreep(snapshots, 7),
      ),
      Array.concat(
        detectUnreviewedAiGrowth(snapshots, 10.0),
        detectSustainedFriction(snapshots, 70.0, 5),
      ),
    ),
    detectPositivePatterns(snapshots),
  )
}

// ===========================================================================
// Gamification
// ===========================================================================

/// XP awarded per positive pattern type.
let xpForPattern = (kind: patternKind): int =>
  switch kind {
  | ReviewedAiCode => 25
  | TodoReduction => 15
  | FindingsReduction => 30
  | TypeCheckCleanup => 20
  | _ => 0
  }

/// XP category for a positive pattern.
let categoryForPattern = (kind: patternKind): option<xpCategory> =>
  switch kind {
  | ReviewedAiCode => Some(CodeReview)
  | TodoReduction => Some(Housekeeping)
  | FindingsReduction => Some(Security)
  | TypeCheckCleanup => Some(TypeSafety)
  | _ => None
  }

/// Compute developer level from total XP (logarithmic scaling).
let levelFromXp = (totalXp: int): int => {
  if totalXp <= 0 {
    1
  } else {
    let raw = Math.log(Int.toFloat(totalXp) /. 100.0) /. Math.log(1.5)
    Math.Int.max(1, Float.toInt(raw) + 1)
  }
}

/// Award XP for a pattern detection.
let awardXp = (profile: developerProfile, kind: patternKind): developerProfile => {
  let amount = xpForPattern(kind)
  if amount <= 0 {
    profile
  } else {
    let newTotal = profile.totalXp + amount
    let category = categoryForPattern(kind)
    let newXp = switch category {
    | Some(cat) => {
        let found = ref(false)
        let updated =
          profile.xp->Array.map(((c, v)) =>
            if c === cat {
              found := true
              (c, v + amount)
            } else {
              (c, v)
            }
          )
        if found.contents {
          updated
        } else {
          Array.concat(updated, [(cat, amount)])
        }
      }
    | None => profile.xp
    }
    {
      ...profile,
      xp: newXp,
      totalXp: newTotal,
      level: levelFromXp(newTotal),
    }
  }
}
