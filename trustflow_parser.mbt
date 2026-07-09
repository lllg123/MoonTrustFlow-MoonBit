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
fn parse_line(
  text : String,
  line_number : Int,
  model : Model,
) -> Result[Unit, TrustFlowError] {
  let tokens = match tokenize(text, line_number) {
    Ok(tokens) => tokens
    Err(err) => return Err(err)
  }
  if tokens.length() == 0 {
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
