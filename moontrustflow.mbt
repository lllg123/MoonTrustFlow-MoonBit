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
  Normal
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
  path : Array[String]
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
  source : String
  sink : String
  path : Array[String]
  message : String
} derive(Eq)

///|
pub(all) enum TrustFlowError {
  UnknownDirective(Position, String)
  MissingNodeName(Position)
  DuplicateNode(Position, String)
  MissingArrow(Position)
  MissingPathNode(Position)
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
    Normal => "normal"
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
    MissingArrow(pos) =>
      "line \{pos.line}, column \{pos.column}: missing arrow"
    MissingPathNode(pos) =>
      "line \{pos.line}, column \{pos.column}: missing path node"
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
fn find_node(model : Model, name : String) -> Node? {
  for node in model.nodes {
    if node.name == name {
      return Some(node)
    }
  }
  None
}

///|
fn has_node(model : Model, name : String) -> Bool {
  find_node(model, name) is Some(_)
}

///|
fn is_sink(model : Model, name : String) -> Bool {
  match find_node(model, name) {
    Some(node) => node.kind == Sink
    None => false
  }
}

///|
fn is_sanitizer(model : Model, name : String) -> Bool {
  match find_node(model, name) {
    Some(node) => node.kind == Sanitizer
    None => false
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
  } else if directive == "node" {
    parse_node(Normal, tokens, line_number, model)
  } else if directive == "edge" {
    parse_edge(tokens, line_number, model)
  } else if directive == "allow" {
    parse_allow(tokens, line_number, model)
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
    return Err(MissingNodeName({ line: line_number, column: tokens[0].length() + 2 }))
  }
  let name = tokens[1]
  if has_node(model, name) {
    return Err(DuplicateNode({ line: line_number, column: tokens[0].length() + 2 }, name))
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
    return Err(MissingArrow({ line: line_number, column: 17 }))
  }
  if tokens.length() < 4 {
    return Err(MissingPathNode({ line: line_number, column: 1 }))
  }
  let label = if tokens.length() >= 5 { tokens[4] } else { "" }
  model.edges.push({ from: tokens[1], to: tokens[3], label })
  Ok(())
}

///|
fn parse_allow(
  tokens : Array[String],
  line_number : Int,
  model : Model,
) -> Result[Unit, TrustFlowError] {
  if tokens.length() < 2 {
    return Err(MissingPathNode({ line: line_number, column: 7 }))
  }
  let path : Array[String] = []
  let mut expect_node = true
  for i in 1..<tokens.length() {
    if expect_node {
      if tokens[i] == "->" {
        return Err(MissingPathNode({ line: line_number, column: 1 }))
      }
      path.push(tokens[i])
      expect_node = false
    } else {
      if tokens[i] != "->" {
        return Err(MissingArrow({ line: line_number, column: 1 }))
      }
      expect_node = true
    }
  }
  if expect_node {
    return Err(MissingPathNode({ line: line_number, column: 1 }))
  }
  model.policies.push({ path, })
  Ok(())
}

///|
fn tokenize(text : String, line_number : Int) -> Result[Array[String], TrustFlowError] {
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
