///|
pub(all) enum RiskBand {
  Low
  Guarded
  High
  Critical
} derive(Eq, Debug, ToJson)

///|
pub(all) enum ModelIssueKind {
  EmptyModel
  OrphanNode
  MissingSource
  MissingSink
  BrokenEdge
  UnreachableSink
  UnusedPolicy
  InvalidSeverity
  DuplicatePolicy
} derive(Eq, Debug, ToJson)

///|
pub(all) struct GraphMetrics {
  node_count : Int
  edge_count : Int
  source_count : Int
  sink_count : Int
  sanitizer_count : Int
  boundary_count : Int
  policy_count : Int
  reachable_source_count : Int
  reachable_sink_count : Int
  max_out_degree : Int
  max_in_degree : Int
  connected_component_count : Int
  cycle_hint_count : Int
} derive(Eq, Debug, ToJson)

///|
pub(all) struct ModelIssue {
  kind : ModelIssueKind
  subject : String
  detail : String
  severity : String
  recommendation : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct PolicyCoverage {
  allow_count : Int
  deny_count : Int
  require_count : Int
  covered_policy_count : Int
  reachable_policy_count : Int
  high_severity_count : Int
  medium_severity_count : Int
  low_severity_count : Int
  coverage_percent : Int
} derive(Eq, Debug, ToJson)

///|
pub(all) struct ModelAssessment {
  metrics : GraphMetrics
  coverage : PolicyCoverage
  issues : Array[ModelIssue]
  risk_score : Int
  risk_band : RiskBand
  recommendation_count : Int
} derive(Eq, Debug, ToJson)

///|
pub fn risk_band_name(band : RiskBand) -> String {
  match band {
    Low => "low"
    Guarded => "guarded"
    High => "high"
    Critical => "critical"
  }
}

///|
pub fn issue_kind_name(kind : ModelIssueKind) -> String {
  match kind {
    EmptyModel => "empty_model"
    OrphanNode => "orphan_node"
    MissingSource => "missing_source"
    MissingSink => "missing_sink"
    BrokenEdge => "broken_edge"
    UnreachableSink => "unreachable_sink"
    UnusedPolicy => "unused_policy"
    InvalidSeverity => "invalid_severity"
    DuplicatePolicy => "duplicate_policy"
  }
}

///|
pub fn measure_model(model : Model) -> GraphMetrics {
  let source_count = count_nodes_of_kind(model, Source)
  let sink_count = count_nodes_of_kind(model, Sink)
  let sanitizer_count = count_nodes_of_kind(model, Sanitizer)
  let boundary_count = count_nodes_of_kind(model, Boundary)
  let mut max_out_degree = 0
  let mut max_in_degree = 0
  for node in model.nodes {
    let out_degree = outgoing_count(model, node.name)
    let in_degree = incoming_count(model, node.name)
    if out_degree > max_out_degree {
      max_out_degree = out_degree
    }
    if in_degree > max_in_degree {
      max_in_degree = in_degree
    }
  }
  let mut reachable_source_count = 0
  let mut reachable_sink_count = 0
  for node in model.nodes {
    if node.kind == Source && has_reachable_sink(model, node.name) {
      reachable_source_count += 1
    }
    if node.kind == Sink && has_reachable_source(model, node.name) {
      reachable_sink_count += 1
    }
  }
  {
    node_count: model.nodes.length(),
    edge_count: model.edges.length(),
    source_count,
    sink_count,
    sanitizer_count,
    boundary_count,
    policy_count: model.policies.length(),
    reachable_source_count,
    reachable_sink_count,
    max_out_degree,
    max_in_degree,
    connected_component_count: count_components(model),
    cycle_hint_count: count_cycle_hints(model),
  }
}

///|
pub fn assess_model(model : Model) -> ModelAssessment {
  let metrics = measure_model(model)
  let coverage = measure_policy_coverage(model)
  let issues = collect_model_issues(model, metrics, coverage)
  let risk_score = calculate_risk_score(metrics, coverage, issues)
  {
    metrics,
    coverage,
    issues,
    risk_score,
    risk_band: risk_band_for_score(risk_score),
    recommendation_count: count_recommendations(metrics, coverage),
  }
}

///|
pub fn assessment_json(assessment : ModelAssessment) -> String {
  assessment.to_json().stringify(indent=2)
}

///|
pub fn format_assessment(assessment : ModelAssessment) -> String {
  let out = StringBuilder()
  out.write_string("model assessment")
  out.write_string("\nrisk_score=\{assessment.risk_score}")
  out.write_string("\nrisk_band=\{risk_band_name(assessment.risk_band)}")
  out.write_string(
    "\nnodes=\{assessment.metrics.node_count}, edges=\{assessment.metrics.edge_count}, policies=\{assessment.metrics.policy_count}",
  )
  out.write_string("\npolicy_coverage=\{assessment.coverage.coverage_percent}%")
  out.write_string("\nissues=\{assessment.issues.length()}")
  for issue in assessment.issues {
    out.write_string(
      "\n[\{issue.severity}] \{issue_kind_name(issue.kind)}: \{issue.subject} - \{issue.detail}",
    )
    out.write_string("\n  recommendation: \{issue.recommendation}")
  }
  out.to_string()
}

///|
fn count_nodes_of_kind(model : Model, wanted : NodeKind) -> Int {
  let mut total = 0
  for node in model.nodes {
    if node.kind == wanted {
      total += 1
    }
  }
  total
}

///|
fn outgoing_count(model : Model, name : String) -> Int {
  let mut total = 0
  for edge in model.edges {
    if edge.from == name {
      total += 1
    }
  }
  total
}

///|
fn incoming_count(model : Model, name : String) -> Int {
  let mut total = 0
  for edge in model.edges {
    if edge.to == name {
      total += 1
    }
  }
  total
}

///|
fn has_node_named(model : Model, name : String) -> Bool {
  for node in model.nodes {
    if node.name == name {
      return true
    }
  }
  false
}

///|
fn node_kind_for(model : Model, name : String) -> NodeKind? {
  for node in model.nodes {
    if node.name == name {
      return Some(node.kind)
    }
  }
  None
}

///|
fn has_reachable_sink(model : Model, start : String) -> Bool {
  let seen : Array[String] = []
  let queue : Array[String] = [start]
  for ;; {
    if queue.length() == 0 {
      break
    }
    let current = queue.remove(0)
    if seen.contains(current) {
      continue
    }
    seen.push(current)
    match node_kind_for(model, current) {
      Some(Sink) => return true
      _ => ()
    }
    for edge in model.edges {
      if edge.from == current && !seen.contains(edge.to) {
        queue.push(edge.to)
      }
    }
  }
  false
}

///|
fn has_reachable_source(model : Model, start : String) -> Bool {
  let seen : Array[String] = []
  let queue : Array[String] = [start]
  for ;; {
    if queue.length() == 0 {
      break
    }
    let current = queue.remove(0)
    if seen.contains(current) {
      continue
    }
    seen.push(current)
    match node_kind_for(model, current) {
      Some(Source) => return true
      _ => ()
    }
    for edge in model.edges {
      if edge.to == current && !seen.contains(edge.from) {
        queue.push(edge.from)
      }
    }
  }
  false
}

///|
fn count_components(model : Model) -> Int {
  let seen : Array[String] = []
  let mut components = 0
  for node in model.nodes {
    if !seen.contains(node.name) {
      components += 1
      collect_component(model, node.name, seen)
    }
  }
  components
}

///|
fn collect_component(
  model : Model,
  start : String,
  seen : Array[String],
) -> Unit {
  let queue : Array[String] = [start]
  for ;; {
    if queue.length() == 0 {
      break
    }
    let current = queue.remove(0)
    if seen.contains(current) {
      continue
    }
    seen.push(current)
    for edge in model.edges {
      if edge.from == current && !seen.contains(edge.to) {
        queue.push(edge.to)
      }
      if edge.to == current && !seen.contains(edge.from) {
        queue.push(edge.from)
      }
    }
  }
}

///|
fn count_cycle_hints(model : Model) -> Int {
  let mut count = 0
  for edge in model.edges {
    if edge.from == edge.to || has_path(model, edge.to, edge.from) {
      count += 1
    }
  }
  count
}

///|
fn has_path(model : Model, start : String, target : String) -> Bool {
  if start == target {
    return true
  }
  let seen : Array[String] = []
  let queue : Array[String] = [start]
  for ;; {
    if queue.length() == 0 {
      break
    }
    let current = queue.remove(0)
    if seen.contains(current) {
      continue
    }
    seen.push(current)
    for edge in model.edges {
      if edge.from == current {
        if edge.to == target {
          return true
        }
        if !seen.contains(edge.to) {
          queue.push(edge.to)
        }
      }
    }
  }
  false
}

///|
fn measure_policy_coverage(model : Model) -> PolicyCoverage {
  let mut allow_count = 0
  let mut deny_count = 0
  let mut require_count = 0
  let mut reachable_count = 0
  let mut covered_count = 0
  let mut high_count = 0
  let mut medium_count = 0
  let mut low_count = 0
  for policy in model.policies {
    match policy.kind {
      Allow => allow_count += 1
      Deny => deny_count += 1
      Require => require_count += 1
    }
    match policy.severity {
      "high" => high_count += 1
      "medium" => medium_count += 1
      _ => low_count += 1
    }
    if policy.path.length() >= 2 &&
      has_path(model, policy.path[0], policy.path[policy.path.length() - 1]) {
      reachable_count += 1
      if policy.kind == Allow ||
        policy.through == "" ||
        has_policy_control_point(model, policy) {
        covered_count += 1
      }
    }
  }
  let coverage_percent = if model.policies.length() == 0 {
    0
  } else {
    covered_count * 100 / model.policies.length()
  }
  {
    allow_count,
    deny_count,
    require_count,
    covered_policy_count: covered_count,
    reachable_policy_count: reachable_count,
    high_severity_count: high_count,
    medium_severity_count: medium_count,
    low_severity_count: low_count,
    coverage_percent,
  }
}

///|
fn has_policy_control_point(model : Model, policy : Policy) -> Bool {
  if policy.through == "" {
    return true
  }
  for edge in model.edges {
    if edge.from == policy.through || edge.to == policy.through {
      return true
    }
  }
  false
}

///|
fn collect_model_issues(
  model : Model,
  metrics : GraphMetrics,
  coverage : PolicyCoverage,
) -> Array[ModelIssue] {
  let issues : Array[ModelIssue] = []
  if model.nodes.length() == 0 {
    issues.push({
      kind: EmptyModel,
      subject: "model",
      detail: "the model contains no nodes",
      severity: "high",
      recommendation: "add at least one source, boundary, and sink",
    })
  }
  if metrics.source_count == 0 {
    issues.push({
      kind: MissingSource,
      subject: "source",
      detail: "no external input node is declared",
      severity: "medium",
      recommendation: "declare the trust boundary where data enters the system",
    })
  }
  if metrics.sink_count == 0 {
    issues.push({
      kind: MissingSink,
      subject: "sink",
      detail: "no security-sensitive output node is declared",
      severity: "medium",
      recommendation: "declare a sink such as a renderer, database, or command executor",
    })
  }
  for edge in model.edges {
    if !has_node_named(model, edge.from) || !has_node_named(model, edge.to) {
      issues.push({
        kind: BrokenEdge,
        subject: "\{edge.from} -> \{edge.to}",
        detail: "edge references a node that is not declared",
        severity: "high",
        recommendation: "declare both endpoints or remove the edge",
      })
    }
  }
  for node in model.nodes {
    if outgoing_count(model, node.name) == 0 &&
      incoming_count(model, node.name) == 0 {
      issues.push({
        kind: OrphanNode,
        subject: node.name,
        detail: "node has no incoming or outgoing edge",
        severity: "low",
        recommendation: "connect the node to a real flow or remove it from the model",
      })
    }
    if node.kind == Sink && !has_reachable_source(model, node.name) {
      issues.push({
        kind: UnreachableSink,
        subject: node.name,
        detail: "sink cannot be reached from any source",
        severity: "medium",
        recommendation: "add the missing service path or explain why the sink is isolated",
      })
    }
  }
  for policy in model.policies {
    if policy.severity != "high" &&
      policy.severity != "medium" &&
      policy.severity != "low" &&
      policy.severity != "info" {
      issues.push({
        kind: InvalidSeverity,
        subject: policy.description,
        detail: "severity is not one of high, medium, low, or info",
        severity: "medium",
        recommendation: "use a supported severity so CI and reports remain comparable",
      })
    }
    if policy.path.length() < 2 ||
      !has_path(model, policy.path[0], policy.path[policy.path.length() - 1]) {
      issues.push({
        kind: UnusedPolicy,
        subject: policy.description,
        detail: "policy endpoint path is not reachable in the graph",
        severity: "low",
        recommendation: "check endpoint names and keep intentional future rules documented",
      })
    }
  }
  if model.policies.length() > 0 && coverage.covered_policy_count == 0 {
    issues.push({
      kind: UnusedPolicy,
      subject: "policy-set",
      detail: "no policy currently covers a reachable path",
      severity: "high",
      recommendation: "add executable rules for the declared source-to-sink flows",
    })
  }
  issues
}

///|
fn calculate_risk_score(
  metrics : GraphMetrics,
  coverage : PolicyCoverage,
  issues : Array[ModelIssue],
) -> Int {
  let mut score = 0
  score += metrics.sink_count * 2
  score += metrics.edge_count / 4
  score += metrics.cycle_hint_count
  score += (100 - coverage.coverage_percent) / 5
  for issue in issues {
    match issue.severity {
      "high" => score += 12
      "medium" => score += 6
      "low" => score += 2
      _ => score += 1
    }
  }
  if score > 100 {
    100
  } else {
    score
  }
}

///|
fn risk_band_for_score(score : Int) -> RiskBand {
  if score >= 75 {
    Critical
  } else if score >= 45 {
    High
  } else if score >= 20 {
    Guarded
  } else {
    Low
  }
}

///|
fn count_recommendations(
  metrics : GraphMetrics,
  coverage : PolicyCoverage,
) -> Int {
  let mut count = 0
  if metrics.source_count == 0 {
    count += 1
  }
  if metrics.sink_count == 0 {
    count += 1
  }
  if metrics.reachable_sink_count < metrics.sink_count {
    count += metrics.sink_count - metrics.reachable_sink_count
  }
  if coverage.coverage_percent < 100 {
    count += 1
  }
  count
}
