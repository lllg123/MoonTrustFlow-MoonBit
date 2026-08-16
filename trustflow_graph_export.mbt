///|
pub(all) enum GraphExportFormat {
  GraphJson
  GraphDot
  GraphText
} derive(Eq, Debug, ToJson)

///|
pub(all) struct GraphNodeRecord {
  id : String
  kind : String
  description : String
  incoming : Int
  outgoing : Int
  source_reachable : Bool
  sink_reachable : Bool
} derive(Eq, Debug, ToJson)

///|
pub(all) struct GraphEdgeRecord {
  from : String
  to : String
  label : String
  boundary_crossing : Bool
} derive(Eq, Debug, ToJson)

///|
pub(all) struct GraphExport {
  format : String
  nodes : Array[GraphNodeRecord]
  edges : Array[GraphEdgeRecord]
  digest : String
} derive(Eq, Debug, ToJson)

///|
pub fn export_graph(model : Model, format : GraphExportFormat) -> String {
  match format {
    GraphJson => export_graph_json(model)
    GraphDot => export_graph_dot(model)
    GraphText => export_graph_text(model)
  }
}

///|
pub fn export_graph_json(model : Model) -> String {
  graph_export(model, "json").to_json().stringify(indent=2)
}

///|
pub fn export_graph_dot(model : Model) -> String {
  let out = StringBuilder()
  out.write_string("digraph MoonTrustFlow {")
  for node in model.nodes {
    out.write_string("\n  \"")
    out.write_string(node.name)
    out.write_string("\" [label=\"")
    out.write_string(node.name + " (" + node_kind_name(node.kind) + ")")
    out.write_string("\"];")
  }
  for edge in model.edges {
    out.write_string("\n  \"")
    out.write_string(edge.from)
    out.write_string("\" -> \"")
    out.write_string(edge.to)
    out.write_string("\" [label=\"")
    out.write_string(edge.label)
    out.write_string("\"];")
  }
  out.write_string("\n}")
  out.to_string()
}

///|
pub fn export_graph_text(model : Model) -> String {
  let graph = graph_export(model, "text")
  let out = StringBuilder()
  out.write_string("graph digest=\{graph.digest}")
  out.write_string(
    "\nnodes=\{graph.nodes.length()} edges=\{graph.edges.length()}",
  )
  for node in graph.nodes {
    out.write_string("\nnode \{node.id} kind=\{node.kind}")
    out.write_string(" in=\{node.incoming} out=\{node.outgoing}")
    out.write_string(" source_reachable=\{node.source_reachable}")
    out.write_string(" sink_reachable=\{node.sink_reachable}")
  }
  for edge in graph.edges {
    out.write_string(
      "\nedge \{edge.from} -> \{edge.to} label=\"\{edge.label}\"",
    )
  }
  out.to_string()
}

///|
pub fn graph_export(model : Model, format : String) -> GraphExport {
  let nodes : Array[GraphNodeRecord] = []
  let edges : Array[GraphEdgeRecord] = []
  for node in model.nodes {
    nodes.push({
      id: node.name,
      kind: node_kind_name(node.kind),
      description: node.description,
      incoming: graph_incoming(model, node.name),
      outgoing: graph_outgoing(model, node.name),
      source_reachable: has_reachable_source(model, node.name),
      sink_reachable: has_reachable_sink(model, node.name),
    })
  }
  for edge in model.edges {
    edges.push({
      from: edge.from,
      to: edge.to,
      label: edge.label,
      boundary_crossing: is_boundary_crossing(model, edge),
    })
  }
  { format, nodes, edges, digest: graph_digest(model) }
}

///|
pub fn graph_digest(model : Model) -> String {
  let mut score = model.nodes.length() * 31 + model.edges.length() * 17
  for node in model.nodes {
    score += node.name.length() * 3 + node_kind_name(node.kind).length()
  }
  for edge in model.edges {
    score += edge.from.length() + edge.to.length() + edge.label.length()
  }
  "mtf-\{score}-\{model.nodes.length()}-\{model.edges.length()}"
}

///|
pub fn graph_node_names_by_kind(
  model : Model,
  kind : NodeKind,
) -> Array[String] {
  let result : Array[String] = []
  for node in model.nodes {
    if node.kind == kind {
      result.push(node.name)
    }
  }
  result
}

///|
pub fn graph_critical_nodes(model : Model) -> Array[String] {
  let result : Array[String] = []
  for node in model.nodes {
    let in_degree = graph_incoming(model, node.name)
    let out_degree = graph_outgoing(model, node.name)
    if in_degree > 1 || out_degree > 1 || node.kind == Boundary {
      result.push(node.name)
    }
  }
  result
}

///|
pub fn graph_boundary_edges(model : Model) -> Array[Edge] {
  let result : Array[Edge] = []
  for edge in model.edges {
    if is_boundary_crossing(model, edge) {
      result.push(edge)
    }
  }
  result
}

///|
fn graph_incoming(model : Model, name : String) -> Int {
  let mut count = 0
  for edge in model.edges {
    if edge.to == name {
      count += 1
    }
  }
  count
}

///|
fn graph_outgoing(model : Model, name : String) -> Int {
  let mut count = 0
  for edge in model.edges {
    if edge.from == name {
      count += 1
    }
  }
  count
}

///|
fn graph_kind(model : Model, name : String) -> NodeKind? {
  for node in model.nodes {
    if node.name == name {
      return Some(node.kind)
    }
  }
  None
}

///|
fn is_boundary_crossing(model : Model, edge : Edge) -> Bool {
  match (graph_kind(model, edge.from), graph_kind(model, edge.to)) {
    (Some(Boundary), _) => true
    (_, Some(Boundary)) => true
    (Some(Source), Some(Sink)) => true
    _ => false
  }
}
