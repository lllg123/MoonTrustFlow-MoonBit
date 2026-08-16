///|
pub(all) enum ExplanationKind {
  ForbiddenRoute
  MissingSanitizer
  ReviewedException
  UnknownRule
} derive(Eq, Debug, ToJson)

///|
pub(all) struct RemediationAction {
  title : String
  command : String
  rationale : String
  priority : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct FindingExplanation {
  kind : ExplanationKind
  title : String
  summary : String
  affected_path : String
  risk : String
  actions : Array[RemediationAction]
} derive(Eq, Debug, ToJson)

///|
pub fn explanation_kind_name(kind : ExplanationKind) -> String {
  match kind {
    ForbiddenRoute => "forbidden_route"
    MissingSanitizer => "missing_sanitizer"
    ReviewedException => "reviewed_exception"
    UnknownRule => "unknown_rule"
  }
}

///|
pub fn explain_finding(finding : Finding) -> FindingExplanation {
  let kind = if finding.rule == "deny" {
    ForbiddenRoute
  } else if finding.rule == "require" {
    MissingSanitizer
  } else {
    UnknownRule
  }
  let path = finding.path.join(" -> ")
  let actions = remediation_actions(kind, finding)
  {
    kind,
    title: explanation_title(kind),
    summary: explanation_summary(kind, finding),
    affected_path: path,
    risk: finding.severity,
    actions,
  }
}

///|
pub fn explain_findings(findings : Array[Finding]) -> Array[FindingExplanation] {
  let explanations : Array[FindingExplanation] = []
  for finding in findings {
    explanations.push(explain_finding(finding))
  }
  explanations
}

///|
pub fn explanations_json(findings : Array[Finding]) -> String {
  explain_findings(findings).to_json().stringify(indent=2)
}

///|
pub fn format_explanation(explanation : FindingExplanation) -> String {
  let out = StringBuilder()
  out.write_string("[\{explanation.risk}] \{explanation.title}")
  out.write_string("\npath=\{explanation.affected_path}")
  out.write_string("\n\{explanation.summary}")
  for action in explanation.actions {
    out.write_string("\n- \{action.priority}: \{action.title}")
    out.write_string("\n  command: \{action.command}")
    out.write_string("\n  why: \{action.rationale}")
  }
  out.to_string()
}

///|
pub fn format_explanations(findings : Array[Finding]) -> String {
  let explanations = explain_findings(findings)
  let out = StringBuilder()
  out.write_string("explanations=\{explanations.length()}")
  for explanation in explanations {
    out.write_char('\n')
    out.write_string(format_explanation(explanation))
  }
  out.to_string()
}

///|
fn explanation_title(kind : ExplanationKind) -> String {
  match kind {
    ForbiddenRoute => "Forbidden source-to-sink route"
    MissingSanitizer => "Required control point is missing"
    ReviewedException => "Reviewed exception requires confirmation"
    UnknownRule => "Policy finding requires review"
  }
}

///|
fn explanation_summary(kind : ExplanationKind, finding : Finding) -> String {
  match kind {
    ForbiddenRoute =>
      "The declared deny policy found a reachable path that crosses the trust boundary without an explicit exception. \{finding.message}"
    MissingSanitizer =>
      "The declared require policy found a reachable path that does not pass through its control point. \{finding.message}"
    ReviewedException =>
      "The finding uses a rule kind that is not part of the standard explainability vocabulary. \{finding.message}"
    UnknownRule =>
      "The analyzer returned a finding with an unrecognized rule label. \{finding.message}"
  }
}

///|
fn remediation_actions(
  kind : ExplanationKind,
  finding : Finding,
) -> Array[RemediationAction] {
  let actions : Array[RemediationAction] = []
  let path = finding.path.join(" -> ")
  match kind {
    ForbiddenRoute => {
      actions.push({
        title: "Route the data through a sanitizer",
        command: "add sanitizer <name> and an edge before \{finding.sink}",
        rationale: "A deny finding should be removed by changing the flow, not by hiding the report.",
        priority: "P0",
      })
      actions.push({
        title: "Add a reviewed allow path only when justified",
        command: "allow \{path} \"reviewed reason\"",
        rationale: "An exact-path exception documents a deliberate boundary decision and remains auditable.",
        priority: "P1",
      })
    }
    MissingSanitizer => {
      actions.push({
        title: "Insert the required control point",
        command: "add sanitizer \{finding.suggestion}",
        rationale: "The require rule is an enforceable contract for every reachable path.",
        priority: "P0",
      })
      actions.push({
        title: "Test both safe and unsafe branches",
        command: "add one fixture for each branch in fixtures/benchmarks",
        rationale: "Branch-specific fixtures prevent a future refactor from silently bypassing the control point.",
        priority: "P1",
      })
    }
    ReviewedException =>
      actions.push({
        title: "Confirm the policy vocabulary",
        command: "use allow, deny, or require in the .mtf model",
        rationale: "Stable rule names keep CLI, JSON, and SARIF consumers interoperable.",
        priority: "P1",
      })
    UnknownRule =>
      actions.push({
        title: "Review the generated finding",
        command: "run moon run cmd/main -- --json",
        rationale: "The structured report is the canonical handoff between the analyzer and external tooling.",
        priority: "P1",
      })
  }
  actions
}

///|
pub fn explanation_priority(explanation : FindingExplanation) -> String {
  if explanation.risk == "high" {
    "P0"
  } else if explanation.risk == "medium" {
    "P1"
  } else {
    "P2"
  }
}

///|
pub fn explanation_has_action(
  explanation : FindingExplanation,
  title : String,
) -> Bool {
  for action in explanation.actions {
    if action.title == title {
      return true
    }
  }
  false
}

///|
pub fn count_explanations_by_priority(
  explanations : Array[FindingExplanation],
  priority : String,
) -> Int {
  let mut count = 0
  for explanation in explanations {
    if explanation_priority(explanation) == priority {
      count += 1
    }
  }
  count
}

///|
pub fn explanation_summary_line(
  explanations : Array[FindingExplanation],
) -> String {
  let p0 = count_explanations_by_priority(explanations, "P0")
  let p1 = count_explanations_by_priority(explanations, "P1")
  let p2 = count_explanations_by_priority(explanations, "P2")
  "P0=\{p0}, P1=\{p1}, P2=\{p2}"
}
