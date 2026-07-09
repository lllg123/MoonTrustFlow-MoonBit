///|
pub fn analyze(model : Model) -> Array[Finding] {
  let findings : Array[Finding] = []
  for policy in model.policies {
    match policy.kind {
      Allow => ()
      Deny => evaluate_deny(model, policy, findings)
      Require => evaluate_require(model, policy, findings)
    }
  }
  findings
}

///|
fn evaluate_deny(
  model : Model,
  policy : Policy,
  findings : Array[Finding],
) -> Unit {
  if policy.path.length() < 2 {
    return
  }
  let paths = find_paths(
    model,
    policy.path[0],
    policy.path[policy.path.length() - 1],
  )
  for path in paths {
    if policy_matches_path(policy.path, path) && !is_allowed(model, path) {
      findings.push({
        severity: policy.severity,
        rule: "deny",
        source: path[0],
        sink: path[path.length() - 1],
        path,
        message: message_or_default(
          policy, "forbidden policy path is reachable",
        ),
        suggestion: "review or allow this path explicitly",
      })
    }
  }
}

///|
fn evaluate_require(
  model : Model,
  policy : Policy,
  findings : Array[Finding],
) -> Unit {
  if policy.path.length() < 2 || policy.through == "" {
    return
  }
  let paths = find_paths(
    model,
    policy.path[0],
    policy.path[policy.path.length() - 1],
  )
  for path in paths {
    if policy_matches_path(policy.path, path) &&
      !path_contains(path, policy.through) &&
      !is_allowed(model, path) {
      findings.push({
        severity: policy.severity,
        rule: "require",
        source: path[0],
        sink: path[path.length() - 1],
        path,
        message: message_or_default(
          policy,
          "required control point \{policy.through} is missing",
        ),
        suggestion: "route this path through \{policy.through} or add a reviewed exception",
      })
    }
  }
}

///|
fn message_or_default(policy : Policy, fallback : String) -> String {
  if policy.description == "" {
    fallback
  } else {
    policy.description
  }
}

///|
fn is_allowed(model : Model, path : Array[String]) -> Bool {
  for policy in model.policies {
    if policy.kind == Allow && same_path(policy.path, path) {
      return true
    }
  }
  false
}
