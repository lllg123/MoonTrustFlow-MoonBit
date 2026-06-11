///|
pub(all) struct Position {
  line : Int
  column : Int
} derive(Eq)

///|
pub(all) enum NodeKind {
  Source
  Sink
  Sanitizer
  Boundary
  Normal
} derive(Eq)

///|
pub(all) enum RuleKind {
  Allow
  Deny
  Require
} derive(Eq)

///|
pub(all) struct Node {
  name : String
  kind : NodeKind
  description : String
} derive(Eq)

///|
pub(all) struct Edge {
  from : String
  to : String
  label : String
} derive(Eq)

///|
pub(all) struct Policy {
  kind : RuleKind
  path : Array[String]
  through : String
  severity : String
  description : String
} derive(Eq)

///|
pub(all) struct Model {
  nodes : Array[Node]
  edges : Array[Edge]
  policies : Array[Policy]
} derive(Eq)

///|
pub(all) struct Finding {
  severity : String
  rule : String
  source : String
  sink : String
  path : Array[String]
  message : String
  suggestion : String
} derive(Eq)

///|
pub(all) enum TrustFlowError {
  UnknownDirective(Position, String)
  MissingNodeName(Position)
  DuplicateNode(Position, String)
  MissingArrow(Position)
  MissingPathNode(Position)
  MissingThrough(Position)
  UnterminatedQuote(Position)
} derive(Eq)

///|
pub fn empty_model() -> Model {
  { nodes: [], edges: [], policies: [] }
}

///|
pub fn node_kind_name(kind : NodeKind) -> String {
  match kind {
    Source => "source"
    Sink => "sink"
    Sanitizer => "sanitizer"
    Boundary => "boundary"
    Normal => "normal"
  }
}

///|
pub fn rule_kind_name(kind : RuleKind) -> String {
  match kind {
    Allow => "allow"
    Deny => "deny"
    Require => "require"
  }
}

///|
pub fn format_error(err : TrustFlowError) -> String {
  match err {
    UnknownDirective(pos, name) =>
      "line \{pos.line}, column \{pos.column}: unknown directive \{name}"
    MissingNodeName(pos) =>
      "line \{pos.line}, column \{pos.column}: missing node name"
    DuplicateNode(pos, name) =>
      "line \{pos.line}, column \{pos.column}: duplicate node \{name}"
    MissingArrow(pos) => "line \{pos.line}, column \{pos.column}: missing arrow"
    MissingPathNode(pos) =>
      "line \{pos.line}, column \{pos.column}: missing path node"
    MissingThrough(pos) =>
      "line \{pos.line}, column \{pos.column}: require policy missing through="
    UnterminatedQuote(pos) =>
      "line \{pos.line}, column \{pos.column}: unterminated quoted text"
  }
}

///|
pub fn parse_model(input : String) -> Result[Model, TrustFlowError] {
  let model = empty_model()
  let line = StringBuilder()
  let mut line_number = 1
  for c in input.iter() {
    if c == '\n' {
      match parse_line(line.to_string(), line_number, model) {
        Ok(_) => ()
        Err(err) => return Err(err)
      }
      line.reset()
      line_number += 1
    } else if c != '\r' {
      line.write_char(c)
    }
  }
  match parse_line(line.to_string(), line_number, model) {
    Ok(_) => Ok(model)
    Err(err) => Err(err)
  }
}

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
pub fn format_finding(finding : Finding) -> String {
  "[\{finding.severity}] \{finding.rule} violated: \{finding.path.join(" -> ")} | \{finding.message} | suggestion=\{finding.suggestion}"
}

///|
pub fn format_report(findings : Array[Finding]) -> String {
  let out = StringBuilder()
  out.write_string("findings=\{findings.length()}")
  for finding in findings {
    out.write_char('\n')
    out.write_string(format_finding(finding))
  }
  out.to_string()
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
fn find_paths(
  model : Model,
  from : String,
  to : String,
) -> Array[Array[String]] {
  let paths : Array[Array[String]] = []
  collect_paths(model, from, to, [from], paths)
  paths
}

///|
fn collect_paths(
  model : Model,
  current : String,
  target : String,
  path : Array[String],
  paths : Array[Array[String]],
) -> Unit {
  if path.length() > model.nodes.length() + model.edges.length() {
    return
  }
  if current == target && path.length() > 1 {
    paths.push(path.copy())
    return
  }
  for edge in model.edges {
    if edge.from == current && !path_contains(path, edge.to) {
      let next_path = path.copy()
      next_path.push(edge.to)
      collect_paths(model, edge.to, target, next_path, paths)
    }
  }
}

///|
fn policy_matches_path(
  policy_path : Array[String],
  actual_path : Array[String],
) -> Bool {
  if policy_path.length() == 2 {
    actual_path.length() >= 2 &&
    actual_path[0] == policy_path[0] &&
    actual_path[actual_path.length() - 1] == policy_path[1]
  } else {
    same_path(policy_path, actual_path)
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

///|
fn same_path(left : Array[String], right : Array[String]) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if left[i] != right[i] {
      return false
    }
  }
  true
}

///|
fn path_contains(path : Array[String], name : String) -> Bool {
  for node in path {
    if node == name {
      return true
    }
  }
  false
}

///|
fn parse_line(
  text : String,
  line_number : Int,
  model : Model,
) -> Result[Unit, TrustFlowError] {
  let tokens = match tokenize(text, line_number) {
    Ok(tokens) => tokens
    Err(err) => return Err(err)
  }
  if tokens.length() == 0 || starts_with(tokens[0], "#") {
    return Ok(())
  }
  let directive = tokens[0]
  if directive == "source" {
    parse_node(Source, tokens, line_number, model)
  } else if directive == "sink" {
    parse_node(Sink, tokens, line_number, model)
  } else if directive == "sanitizer" {
    parse_node(Sanitizer, tokens, line_number, model)
  } else if directive == "boundary" {
    parse_node(Boundary, tokens, line_number, model)
  } else if directive == "node" {
    parse_node(Normal, tokens, line_number, model)
  } else if directive == "edge" {
    parse_edge(tokens, line_number, model)
  } else if directive == "allow" {
    parse_policy(Allow, tokens, line_number, model)
  } else if directive == "deny" {
    parse_policy(Deny, tokens, line_number, model)
  } else if directive == "require" {
    parse_policy(Require, tokens, line_number, model)
  } else {
    Err(UnknownDirective({ line: line_number, column: 1 }, directive))
  }
}

///|
fn parse_node(
  kind : NodeKind,
  tokens : Array[String],
  line_number : Int,
  model : Model,
) -> Result[Unit, TrustFlowError] {
  if tokens.length() < 2 {
    return Err(
      MissingNodeName({ line: line_number, column: tokens[0].length() + 1 }),
    )
  }
  let name = tokens[1]
  if has_node(model, name) {
    return Err(
      DuplicateNode({ line: line_number, column: tokens[0].length() + 2 }, name),
    )
  }
  let description = if tokens.length() >= 3 { tokens[2] } else { "" }
  model.nodes.push({ name, kind, description })
  Ok(())
}

///|
fn parse_edge(
  tokens : Array[String],
  line_number : Int,
  model : Model,
) -> Result[Unit, TrustFlowError] {
  if tokens.length() < 2 {
    return Err(MissingPathNode({ line: line_number, column: 6 }))
  }
  if tokens.length() < 3 || tokens[2] != "->" {
    return Err(
      MissingArrow({
        line: line_number,
        column: tokens[0].length() + tokens[1].length() + 3,
      }),
    )
  }
  if tokens.length() < 4 {
    return Err(MissingPathNode({ line: line_number, column: 1 }))
  }
  let label = if tokens.length() >= 5 { tokens[4] } else { "" }
  model.edges.push({ from: tokens[1], to: tokens[3], label })
  Ok(())
}

///|
fn parse_policy(
  kind : RuleKind,
  tokens : Array[String],
  line_number : Int,
  model : Model,
) -> Result[Unit, TrustFlowError] {
  if tokens.length() < 2 {
    return Err(
      MissingPathNode({ line: line_number, column: tokens[0].length() + 2 }),
    )
  }
  let path : Array[String] = []
  let mut expect_node = true
  let mut through = ""
  let mut severity = default_severity(kind)
  let description = StringBuilder()
  let mut has_description = false
  let mut i = 1
  let mut reading_options = false
  while i < tokens.length() {
    let token = tokens[i]
    if starts_with(token, "severity=") {
      severity = strip_prefix(token, "severity=")
      reading_options = true
    } else if starts_with(token, "through=") {
      through = strip_prefix(token, "through=")
      reading_options = true
    } else if !reading_options && (token == "->" || expect_node) {
      if expect_node {
        if token == "->" {
          return Err(MissingPathNode({ line: line_number, column: 1 }))
        }
        path.push(token)
        expect_node = false
      } else {
        if token != "->" {
          return Err(MissingArrow({ line: line_number, column: 1 }))
        }
        expect_node = true
      }
    } else {
      if has_description {
        description.write_char(' ')
      }
      description.write_string(token)
      has_description = true
      reading_options = true
    }
    i += 1
  }
  if expect_node {
    return Err(MissingPathNode({ line: line_number, column: 1 }))
  }
  if kind == Require && through == "" {
    return Err(MissingThrough({ line: line_number, column: 1 }))
  }
  model.policies.push({
    kind,
    path,
    through,
    severity,
    description: description.to_string(),
  })
  Ok(())
}

///|
fn default_severity(kind : RuleKind) -> String {
  match kind {
    Allow => "info"
    Deny => "high"
    Require => "medium"
  }
}

///|
fn has_node(model : Model, name : String) -> Bool {
  for node in model.nodes {
    if node.name == name {
      return true
    }
  }
  false
}

///|
fn tokenize(
  text : String,
  line_number : Int,
) -> Result[Array[String], TrustFlowError] {
  let chars = text.iter().to_array()
  let tokens : Array[String] = []
  let mut i = 0
  while i < chars.length() {
    while i < chars.length() && is_space(chars[i]) {
      i += 1
    }
    if i >= chars.length() {
      continue
    }
    let token = StringBuilder()
    if chars[i] == '"' {
      let quote_pos = { line: line_number, column: i + 1 }
      i += 1
      let mut closed = false
      while i < chars.length() && !closed {
        if chars[i] == '\\' && i + 1 < chars.length() {
          token.write_char(chars[i + 1])
          i += 2
        } else if chars[i] == '"' {
          closed = true
          i += 1
        } else {
          token.write_char(chars[i])
          i += 1
        }
      }
      if !closed {
        return Err(UnterminatedQuote(quote_pos))
      }
    } else {
      while i < chars.length() && !is_space(chars[i]) {
        token.write_char(chars[i])
        i += 1
      }
    }
    tokens.push(token.to_string())
  }
  Ok(tokens)
}

///|
fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\t'
}

///|
fn starts_with(text : String, prefix : String) -> Bool {
  if text.length() < prefix.length() {
    return false
  }
  let text_chars = text.iter().to_array()
  let prefix_chars = prefix.iter().to_array()
  for i in 0..<prefix_chars.length() {
    if text_chars[i] != prefix_chars[i] {
      return false
    }
  }
  true
}

///|
fn strip_prefix(text : String, prefix : String) -> String {
  let chars = text.iter().to_array()
  let out = StringBuilder()
  for i in prefix.length()..<chars.length() {
    out.write_char(chars[i])
  }
  out.to_string()
}
