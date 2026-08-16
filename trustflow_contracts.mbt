///|
pub(all) enum ContractCheckKind {
  RequiredNode
  MinimumGraphSize
  RequiredPolicy
  RequiredControlPoint
  Reachability
  SeverityContract
} derive(Eq, Debug, ToJson)

///|
pub(all) struct ModelContract {
  name : String
  required_node_kinds : Array[String]
  minimum_nodes : Int
  minimum_edges : Int
  required_policy_kinds : Array[String]
  required_control_points : Array[String]
  minimum_severity : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct ContractCheck {
  kind : ContractCheckKind
  name : String
  passed : Bool
  observed : String
  expected : String
  detail : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct ContractReport {
  contract : String
  passed : Bool
  checks : Array[ContractCheck]
  passed_count : Int
  failed_count : Int
} derive(Eq, Debug, ToJson)

///|
pub fn default_model_contract() -> ModelContract {
  {
    name: "trusted-flow-production-model",
    required_node_kinds: ["source", "sink"],
    minimum_nodes: 2,
    minimum_edges: 1,
    required_policy_kinds: ["deny"],
    required_control_points: [],
    minimum_severity: "low",
  }
}

///|
pub fn evaluate_contract(
  model : Model,
  contract : ModelContract,
) -> ContractReport {
  let checks : Array[ContractCheck] = []
  let mut passed_count = 0
  let mut failed_count = 0
  for required_kind in contract.required_node_kinds {
    let observed = count_nodes_by_name(model, required_kind)
    let passed = observed > 0
    checks.push({
      kind: RequiredNode,
      name: required_kind,
      passed,
      observed: "\{observed}",
      expected: "> 0",
      detail: if passed {
        "required node kind is present"
      } else {
        "required node kind is missing"
      },
    })
    if passed {
      passed_count += 1
    } else {
      failed_count += 1
    }
  }
  let graph_size_passed = model.nodes.length() >= contract.minimum_nodes &&
    model.edges.length() >= contract.minimum_edges
  checks.push({
    kind: MinimumGraphSize,
    name: "graph-size",
    passed: graph_size_passed,
    observed: "nodes=\{model.nodes.length()}, edges=\{model.edges.length()}",
    expected: "nodes >= \{contract.minimum_nodes}, edges >= \{contract.minimum_edges}",
    detail: if graph_size_passed {
      "graph has the minimum deployable shape"
    } else {
      "graph is too small for the declared contract"
    },
  })
  if graph_size_passed {
    passed_count += 1
  } else {
    failed_count += 1
  }
  for required_policy in contract.required_policy_kinds {
    let observed = count_policies_by_name(model, required_policy)
    let passed = observed > 0
    checks.push({
      kind: RequiredPolicy,
      name: required_policy,
      passed,
      observed: "\{observed}",
      expected: "> 0",
      detail: if passed {
        "required policy kind is present"
      } else {
        "required policy kind is missing"
      },
    })
    if passed {
      passed_count += 1
    } else {
      failed_count += 1
    }
  }
  for control_point in contract.required_control_points {
    let passed = has_named_node(model, control_point)
    checks.push({
      kind: RequiredControlPoint,
      name: control_point,
      passed,
      observed: if passed {
        "present"
      } else {
        "missing"
      },
      expected: "present",
      detail: if passed {
        "declared control point is available"
      } else {
        "declared control point is missing"
      },
    })
    if passed {
      passed_count += 1
    } else {
      failed_count += 1
    }
  }
  let reachability_passed = all_sources_reach_sink(model)
  checks.push({
    kind: Reachability,
    name: "source-to-sink-reachability",
    passed: reachability_passed,
    observed: if reachability_passed {
      "reachable"
    } else {
      "not-reachable"
    },
    expected: "at least one source reaches a sink",
    detail: if reachability_passed {
      "the contract has an executable data-flow path"
    } else {
      "no source-to-sink path is executable"
    },
  })
  if reachability_passed {
    passed_count += 1
  } else {
    failed_count += 1
  }
  let severity_passed = minimum_severity_present(
    model,
    contract.minimum_severity,
  )
  checks.push({
    kind: SeverityContract,
    name: "minimum-severity",
    passed: severity_passed,
    observed: if severity_passed {
      "satisfied"
    } else {
      "not-satisfied"
    },
    expected: contract.minimum_severity,
    detail: if severity_passed {
      "policy severity contract is satisfied"
    } else {
      "no policy meets the required severity"
    },
  })
  if severity_passed {
    passed_count += 1
  } else {
    failed_count += 1
  }
  {
    contract: contract.name,
    passed: failed_count == 0,
    checks,
    passed_count,
    failed_count,
  }
}

///|
pub fn contract_report_json(report : ContractReport) -> String {
  report.to_json().stringify(indent=2)
}

///|
pub fn format_contract_report(report : ContractReport) -> String {
  let out = StringBuilder()
  out.write_string("contract=\{report.contract} passed=\{report.passed}")
  out.write_string(" checks=\{report.passed_count}/\{report.checks.length()}")
  for check in report.checks {
    let status = if check.passed { "pass" } else { "fail" }
    out.write_string("\n[\{status}] \{check.name}")
    out.write_string(" observed=\{check.observed} expected=\{check.expected}")
    out.write_string("\n  \{check.detail}")
  }
  out.to_string()
}

///|
pub fn contract_is_release_ready(report : ContractReport) -> Bool {
  report.passed
}

///|
fn count_nodes_by_name(model : Model, kind_name : String) -> Int {
  let mut count = 0
  for node in model.nodes {
    if node_kind_name(node.kind) == kind_name {
      count += 1
    }
  }
  count
}

///|
fn count_policies_by_name(model : Model, policy_name : String) -> Int {
  let mut count = 0
  for policy in model.policies {
    if rule_kind_name(policy.kind) == policy_name {
      count += 1
    }
  }
  count
}

///|
fn has_named_node(model : Model, name : String) -> Bool {
  for node in model.nodes {
    if node.name == name {
      return true
    }
  }
  false
}

///|
fn all_sources_reach_sink(model : Model) -> Bool {
  let sources = graph_node_names_by_kind(model, Source)
  if sources.length() == 0 {
    return false
  }
  for source in sources {
    if has_reachable_sink(model, source) {
      return true
    }
  }
  false
}

///|
fn minimum_severity_present(model : Model, minimum : String) -> Bool {
  let target = severity_contract_rank(minimum)
  for policy in model.policies {
    if severity_contract_rank(policy.severity) >= target {
      return true
    }
  }
  false
}

///|
fn severity_contract_rank(severity : String) -> Int {
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
