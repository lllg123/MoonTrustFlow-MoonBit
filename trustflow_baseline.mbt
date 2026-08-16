///|
pub(all) struct BaselineFinding {
  fingerprint : String
  rule : String
  severity : String
  source : String
  sink : String
  path : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct BaselineComparison {
  baseline_count : Int
  current_count : Int
  new_findings : Array[BaselineFinding]
  resolved_findings : Array[BaselineFinding]
  unchanged_findings : Array[BaselineFinding]
  severity_regressions : Array[BaselineFinding]
  passed : Bool
} derive(Eq, Debug, ToJson)

///|
pub fn build_baseline(findings : Array[Finding]) -> Array[BaselineFinding] {
  let baseline : Array[BaselineFinding] = []
  for finding in findings {
    baseline.push(baseline_finding(finding))
  }
  baseline
}

///|
pub fn compare_baseline(
  baseline : Array[BaselineFinding],
  current : Array[Finding],
) -> BaselineComparison {
  let current_baseline = build_baseline(current)
  let new_findings : Array[BaselineFinding] = []
  let resolved_findings : Array[BaselineFinding] = []
  let unchanged_findings : Array[BaselineFinding] = []
  let severity_regressions : Array[BaselineFinding] = []
  for item in current_baseline {
    match baseline_item(baseline, item.fingerprint) {
      Some(previous) => {
        unchanged_findings.push(item)
        if severity_rank(item.severity) > severity_rank(previous.severity) {
          severity_regressions.push(item)
        }
      }
      None => new_findings.push(item)
    }
  }
  for item in baseline {
    if baseline_item(current_baseline, item.fingerprint) is None {
      resolved_findings.push(item)
    }
  }
  {
    baseline_count: baseline.length(),
    current_count: current_baseline.length(),
    new_findings,
    resolved_findings,
    unchanged_findings,
    severity_regressions,
    passed: new_findings.length() == 0 && severity_regressions.length() == 0,
  }
}

///|
pub fn baseline_comparison_json(comparison : BaselineComparison) -> String {
  comparison.to_json().stringify(indent=2)
}

///|
pub fn format_baseline_comparison(comparison : BaselineComparison) -> String {
  let out = StringBuilder()
  out.write_string("baseline=\{comparison.baseline_count}")
  out.write_string(" current=\{comparison.current_count}")
  out.write_string(" new=\{comparison.new_findings.length()}")
  out.write_string(" resolved=\{comparison.resolved_findings.length()}")
  out.write_string(
    " severity_regressions=\{comparison.severity_regressions.length()}",
  )
  out.write_string(" passed=\{comparison.passed}")
  append_baseline_lines(out, "new", comparison.new_findings)
  append_baseline_lines(out, "resolved", comparison.resolved_findings)
  append_baseline_lines(out, "regression", comparison.severity_regressions)
  out.to_string()
}

///|
pub fn baseline_fingerprint(finding : Finding) -> String {
  finding.rule +
  "|" +
  finding.source +
  "|" +
  finding.sink +
  "|" +
  finding.path.join("/")
}

///|
pub fn baseline_is_empty(baseline : Array[BaselineFinding]) -> Bool {
  baseline.length() == 0
}

///|
pub fn baseline_count_by_severity(
  baseline : Array[BaselineFinding],
  severity : String,
) -> Int {
  let mut count = 0
  for item in baseline {
    if item.severity == severity {
      count += 1
    }
  }
  count
}

///|
fn baseline_finding(finding : Finding) -> BaselineFinding {
  {
    fingerprint: baseline_fingerprint(finding),
    rule: finding.rule,
    severity: finding.severity,
    source: finding.source,
    sink: finding.sink,
    path: finding.path.join(" -> "),
  }
}

///|
fn baseline_item(
  baseline : Array[BaselineFinding],
  fingerprint : String,
) -> BaselineFinding? {
  for item in baseline {
    if item.fingerprint == fingerprint {
      return Some(item)
    }
  }
  None
}

///|
fn severity_rank(severity : String) -> Int {
  if severity == "high" {
    3
  } else if severity == "medium" {
    2
  } else if severity == "low" {
    1
  } else {
    0
  }
}

///|
fn append_baseline_lines(
  out : StringBuilder,
  label : String,
  items : Array[BaselineFinding],
) -> Unit {
  for item in items {
    out.write_string("\n\{label}: [\{item.severity}] \{item.path}")
    out.write_string(" (\{item.fingerprint})")
  }
}
