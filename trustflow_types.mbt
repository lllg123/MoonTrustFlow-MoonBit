///|
pub(all) struct Position {
  line : Int
  column : Int
} derive(Eq, Debug, ToJson)

///|
pub(all) enum NodeKind {
  Source
  Sink
  Sanitizer
  Boundary
  Normal
} derive(Eq, Debug, ToJson)

///|
pub(all) enum RuleKind {
  Allow
  Deny
  Require
} derive(Eq, Debug, ToJson)

///|
pub(all) struct Node {
  name : String
  kind : NodeKind
  description : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct Edge {
  from : String
  to : String
  label : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct Policy {
  kind : RuleKind
  path : Array[String]
  through : String
  severity : String
  description : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct Model {
  nodes : Array[Node]
  edges : Array[Edge]
  policies : Array[Policy]
} derive(Eq, Debug, ToJson)

///|
pub(all) struct Finding {
  severity : String
  rule : String
  source : String
  sink : String
  path : Array[String]
  message : String
  suggestion : String
} derive(Eq, Debug, ToJson)

///|
pub(all) enum TrustFlowError {
  UnknownDirective(Position, String)
  MissingNodeName(Position)
  DuplicateNode(Position, String)
  MissingArrow(Position)
  MissingPathNode(Position)
  MissingThrough(Position)
  UnterminatedQuote(Position)
} derive(Eq, Debug, ToJson)

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
pub fn sample_model_text() -> String {
  "source request_body \"external input\"\n" +
  "boundary api_gateway \"trusted service boundary\"\n" +
  "sanitizer escape_html \"html output encoding\"\n" +
  "sink render_html \"html response renderer\"\n" +
  "edge request_body -> api_gateway \"ingress\"\n" +
  "edge api_gateway -> render_html \"response output\"\n" +
  "edge api_gateway -> escape_html \"encode\"\n" +
  "edge escape_html -> render_html \"safe render\"\n" +
  "deny request_body -> render_html severity=high \"raw input must not render directly\"\n" +
  "require request_body -> render_html through=escape_html severity=medium \"html output must be encoded\"\n" +
  "allow request_body -> api_gateway -> escape_html -> render_html \"encoded response path\""
}
