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
