///|
pub(all) struct QualityGateOptions {
  minimum_coverage_percent : Int
  maximum_risk_score : Int
  reject_unreachable_policies : Bool
  reject_invalid_severity : Bool
  require_source_and_sink : Bool
} derive(Eq, Debug, ToJson)

///|
pub(all) struct QualityGateResult {
  passed : Bool
  reasons : Array[String]
  assessment : ModelAssessment
  policy_audit : PolicyAudit
  finding_count : Int
  high_finding_count : Int
  checked_source_sink_pairs : Int
} derive(Eq, Debug, ToJson)

///|
pub(all) struct WorkflowRun {
  source : String
  model : Model
  findings : Array[Finding]
  assessment : ModelAssessment
  policy_audit : PolicyAudit
  quality_gate : QualityGateResult
  sarif : String
} derive(Eq, Debug, ToJson)

///|
pub fn default_quality_gate_options() -> QualityGateOptions {
  {
    minimum_coverage_percent: 80,
    maximum_risk_score: 60,
    reject_unreachable_policies: true,
    reject_invalid_severity: true,
    require_source_and_sink: true,
  }
}

///|
pub fn run_quality_gate(model : Model) -> QualityGateResult {
  run_quality_gate_with_options(model, default_quality_gate_options())
}

///|
pub fn run_quality_gate_with_options(
  model : Model,
  options : QualityGateOptions,
) -> QualityGateResult {
  let assessment = assess_model(model)
  let policy_audit = audit_policies(model)
  let findings = analyze(model)
  let reasons : Array[String] = []
  if options.require_source_and_sink && assessment.metrics.source_count == 0 {
    reasons.push("model has no source node")
  }
  if options.require_source_and_sink && assessment.metrics.sink_count == 0 {
    reasons.push("model has no sink node")
  }
  if policy_audit.coverage_percent < options.minimum_coverage_percent {
    reasons.push("policy coverage is below the configured gate")
  }
  if assessment.risk_score > options.maximum_risk_score {
    reasons.push("risk score exceeds the configured gate")
  }
  if options.reject_unreachable_policies && policy_audit.unreachable_count > 0 {
    reasons.push("one or more policies have unreachable endpoints")
  }
  if options.reject_invalid_severity && has_invalid_severity(model) {
    reasons.push("one or more policies use an invalid severity")
  }
  {
    passed: reasons.length() == 0,
    reasons,
    assessment,
    policy_audit,
    finding_count: findings.length(),
    high_finding_count: count_findings_by_severity(findings, "high"),
    checked_source_sink_pairs: query_source_sink_pairs(model).length(),
  }
}

///|
pub fn run_workflow(source : String, model : Model) -> WorkflowRun {
  let findings = analyze(model)
  let assessment = assess_model(model)
  let policy_audit = audit_policies(model)
  let quality_gate = run_quality_gate(model)
  {
    source,
    model,
    findings,
    assessment,
    policy_audit,
    quality_gate,
    sarif: format_sarif(findings),
  }
}

///|
pub fn run_workflow_text(
  source : String,
  input : String,
) -> Result[WorkflowRun, TrustFlowError] {
  match parse_model(input) {
    Ok(model) => Ok(run_workflow(source, model))
    Err(error) => Err(error)
  }
}

///|
pub fn workflow_json(run : WorkflowRun) -> String {
  run.to_json().stringify(indent=2)
}

///|
pub fn format_quality_gate(result : QualityGateResult) -> String {
  let out = StringBuilder()
  out.write_string("quality_gate={result.passed}")
  out.write_string(" risk={result.assessment.risk_score}")
  out.write_string(" coverage={result.policy_audit.coverage_percent}%")
  out.write_string(" pairs={result.checked_source_sink_pairs}")
  for reason in result.reasons {
    out.write_string("\n- \{reason}")
  }
  out.to_string()
}

///|
pub fn workflow_is_release_ready(run : WorkflowRun) -> Bool {
  run.quality_gate.passed && run.quality_gate.high_finding_count == 0
}

///|
pub fn workflow_changed_since_baseline(
  baseline : Array[BaselineFinding],
  run : WorkflowRun,
) -> BaselineComparison {
  compare_baseline(baseline, run.findings)
}

///|
fn count_findings_by_severity(
  findings : Array[Finding],
  severity : String,
) -> Int {
  let mut count = 0
  for finding in findings {
    if finding.severity == severity {
      count += 1
    }
  }
  count
}

///|
fn has_invalid_severity(model : Model) -> Bool {
  for policy in model.policies {
    if policy.severity != "high" &&
      policy.severity != "medium" &&
      policy.severity != "low" &&
      policy.severity != "info" {
      return true
    }
  }
  false
}
