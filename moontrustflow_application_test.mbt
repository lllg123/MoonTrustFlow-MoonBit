///|
fn application_model() -> Model {
  match parse_model(sample_model_text()) {
    Ok(model) => model
    Err(_) => empty_model()
  }
}

///|
test "assessment reports graph and policy coverage" {
  let model = application_model()
  let assessment = assess_model(model)
  assert_true(assessment.metrics.source_count == 1)
  assert_true(assessment.metrics.sink_count == 1)
  assert_true(assessment.metrics.edge_count == 4)
  assert_true(assessment.coverage.covered_policy_count >= 2)
  assert_true(assessment.risk_score >= 0)
  assert_true(assessment_json(assessment).contains("risk_score"))
}

///|
test "sarif output is consumable by security tooling" {
  let model = application_model()
  let findings = analyze(model)
  let sarif = format_sarif(findings)
  assert_true(sarif.contains("2.1.0"))
  assert_true(sarif.contains("moontrustflow/deny-high"))
  assert_true(sarif.contains("source_body") == false)
}

///|
test "graph exports expose boundary and digest information" {
  let model = application_model()
  let dot = export_graph_dot(model)
  let graph = graph_export(model, "text")
  assert_true(dot.contains("digraph MoonTrustFlow"))
  assert_true(graph.digest.contains("mtf-"))
  assert_true(graph_boundary_edges(model).length() > 0)
  assert_true(graph_critical_nodes(model).length() > 0)
}

///|
test "baseline comparison detects stable and new findings" {
  let model = application_model()
  let findings = analyze(model)
  let baseline = build_baseline(findings)
  let stable = compare_baseline(baseline, findings)
  assert_true(stable.passed)
  assert_true(stable.unchanged_findings.length() == findings.length())
  let changed = compare_baseline(baseline, [])
  assert_true(changed.resolved_findings.length() == findings.length())
}

///|
test "batch analysis preserves parse failures and summaries" {
  let inputs : Array[BatchInput] = [
    { source: "sample.mtf", text: sample_model_text() },
    { source: "broken.mtf", text: "unknown_directive value" },
  ]
  let report = analyze_batch(inputs)
  assert_true(report.summary.total_models == 2)
  assert_true(report.summary.parsed_models == 1)
  assert_true(report.summary.failed_models == 1)
  assert_true(batch_has_failures(report))
  assert_true(batch_item_for(report, "broken.mtf") is Some(_))
}

///|
test "quality gate and contract check are runnable application APIs" {
  let model = application_model()
  let gate = run_quality_gate(model)
  let contract = evaluate_contract(model, default_model_contract())
  let workflow = run_workflow("sample.mtf", model)
  assert_true(gate.checked_source_sink_pairs == 1)
  assert_true(contract.checks.length() >= 5)
  assert_true(workflow.sarif.contains("2.1.0"))
  assert_true(format_quality_gate(gate).contains("quality_gate"))
}
