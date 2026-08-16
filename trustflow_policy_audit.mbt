///|
pub(all) struct PolicyAuditItem {
  index : Int
  kind : String
  endpoint : String
  severity : String
  reachable : Bool
  executable : Bool
  duplicate : Bool
  advice : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct PolicyAudit {
  items : Array[PolicyAuditItem]
  total : Int
  executable : Int
  unreachable_count : Int
  duplicates : Int
  high_risk : Int
  coverage_percent : Int
} derive(Eq, Debug, ToJson)

///|
pub fn audit_policies(model : Model) -> PolicyAudit {
  let items : Array[PolicyAuditItem] = []
  let mut executable_count = 0
  let mut unreachable_count = 0
  let mut duplicates = 0
  let mut high_risk = 0
  for index, policy in model.policies {
    let endpoint = policy_endpoint(policy)
    let reachable = policy_endpoint_reachable(model, policy)
    let is_executable = reachable && policy_is_executable(model, policy)
    let duplicate = is_duplicate_policy(model.policies, index, policy)
    if is_executable {
      executable_count += 1
    } else {
      unreachable_count += 1
    }
    if duplicate {
      duplicates += 1
    }
    if policy.severity == "high" {
      high_risk += 1
    }
    items.push({
      index,
      kind: rule_kind_name(policy.kind),
      endpoint,
      severity: normalize_severity(policy.severity),
      reachable,
      executable: is_executable,
      duplicate,
      advice: policy_advice(policy, reachable, duplicate),
    })
  }
  let coverage_percent = if model.policies.length() == 0 {
    0
  } else {
    executable_count * 100 / model.policies.length()
  }
  {
    items,
    total: model.policies.length(),
    executable: executable_count,
    unreachable_count,
    duplicates,
    high_risk,
    coverage_percent,
  }
}

///|
pub fn policy_audit_json(audit : PolicyAudit) -> String {
  audit.to_json().stringify(indent=2)
}

///|
pub fn format_policy_audit(audit : PolicyAudit) -> String {
  let out = StringBuilder()
  out.write_string("policies=\{audit.total}")
  out.write_string(" executable=\{audit.executable}")
  out.write_string(" unreachable=\{audit.unreachable_count}")
  out.write_string(" duplicates=\{audit.duplicates}")
  out.write_string(" coverage=\{audit.coverage_percent}%")
  for item in audit.items {
    out.write_string("\n#\{item.index} \{item.kind} \{item.endpoint}")
    out.write_string(" severity=\{item.severity} reachable=\{item.reachable}")
    out.write_string(
      " executable=\{item.executable} duplicate=\{item.duplicate}",
    )
    out.write_string("\n  \{item.advice}")
  }
  out.to_string()
}

///|
pub fn normalize_severity(severity : String) -> String {
  if severity == "high" ||
    severity == "medium" ||
    severity == "low" ||
    severity == "info" {
    severity
  } else {
    "medium"
  }
}

///|
pub fn policy_is_executable(model : Model, policy : Policy) -> Bool {
  if !policy_endpoint_reachable(model, policy) {
    return false
  }
  match policy.kind {
    Allow => policy.path.length() >= 2
    Deny => policy.path.length() >= 2
    Require => policy.path.length() >= 2 && policy.through != ""
  }
}

///|
pub fn policy_endpoint_reachable(model : Model, policy : Policy) -> Bool {
  if policy.path.length() < 2 {
    return false
  }
  has_path(model, policy.path[0], policy.path[policy.path.length() - 1])
}

///|
pub fn policy_endpoint(policy : Policy) -> String {
  if policy.path.length() < 2 {
    "<incomplete>"
  } else {
    policy.path[0] + " -> " + policy.path[policy.path.length() - 1]
  }
}

///|
fn is_duplicate_policy(
  policies : Array[Policy],
  index : Int,
  policy : Policy,
) -> Bool {
  let mut current = 0
  for other in policies {
    if current < index &&
      other.kind == policy.kind &&
      same_path(other.path, policy.path) &&
      other.through == policy.through {
      return true
    }
    current += 1
  }
  false
}

///|
fn policy_advice(policy : Policy, reachable : Bool, duplicate : Bool) -> String {
  if duplicate {
    "remove the duplicate policy or document why two identical controls are intentionally retained"
  } else if !reachable {
    "verify source and sink names; this rule currently has no executable graph path"
  } else if policy.kind == Require && policy.through == "" {
    "declare the required sanitizer or boundary explicitly"
  } else if policy.kind == Allow {
    "keep the exception exact and include a review reason in the description"
  } else if policy.severity == "high" {
    "keep this control in CI and require an explicit remediation owner"
  } else {
    "retain a fixture that exercises this policy on every relevant branch"
  }
}
