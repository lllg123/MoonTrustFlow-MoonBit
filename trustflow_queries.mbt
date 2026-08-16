///|
pub(all) struct PathQuery {
  source : String
  sink : String
  include_allowed : Bool
  maximum_paths : Int
} derive(Eq, Debug, ToJson)

///|
pub(all) struct PathSummary {
  source : String
  sink : String
  path_count : Int
  allowed_count : Int
  unsafe_count : Int
  shortest_length : Int
  longest_length : Int
  paths : Array[Array[String]]
} derive(Eq, Debug, ToJson)

///|
pub(all) struct NodeImpact {
  node : String
  kind : String
  paths_from_sources : Int
  paths_to_sinks : Int
  policy_count : Int
  is_control_point : Bool
  impact_score : Int
} derive(Eq, Debug, ToJson)

///|
pub fn default_path_query(source : String, sink : String) -> PathQuery {
  { source, sink, include_allowed: false, maximum_paths: 100 }
}

///|
pub fn query_paths(model : Model, query : PathQuery) -> PathSummary {
  let all_paths = find_paths(model, query.source, query.sink)
  let selected : Array[Array[String]] = []
  let mut allowed_count = 0
  let mut unsafe_count = 0
  let mut shortest_length = 0
  let mut longest_length = 0
  for path in all_paths {
    let allowed = is_allowed(model, path)
    if allowed {
      allowed_count += 1
    } else {
      unsafe_count += 1
    }
    if query.include_allowed || !allowed {
      if query.maximum_paths <= 0 || selected.length() < query.maximum_paths {
        selected.push(path)
      }
    }
    if shortest_length == 0 || path.length() < shortest_length {
      shortest_length = path.length()
    }
    if path.length() > longest_length {
      longest_length = path.length()
    }
  }
  {
    source: query.source,
    sink: query.sink,
    path_count: all_paths.length(),
    allowed_count,
    unsafe_count,
    shortest_length,
    longest_length,
    paths: selected,
  }
}

///|
pub fn query_paths_json(summary : PathSummary) -> String {
  summary.to_json().stringify(indent=2)
}

///|
pub fn format_path_summary(summary : PathSummary) -> String {
  let out = StringBuilder()
  out.write_string("paths \{summary.source} -> \{summary.sink}")
  out.write_string(" total=\{summary.path_count}")
  out.write_string(" allowed=\{summary.allowed_count}")
  out.write_string(" unsafe=\{summary.unsafe_count}")
  out.write_string(" shortest=\{summary.shortest_length}")
  out.write_string(" longest=\{summary.longest_length}")
  for path in summary.paths {
    let path_text = path.join(" -> ")
    out.write_string("\n- \{path_text}")
  }
  out.to_string()
}

///|
pub fn rank_node_impact(model : Model) -> Array[NodeImpact] {
  let result : Array[NodeImpact] = []
  for node in model.nodes {
    let from_sources = count_source_paths(model, node.name)
    let to_sinks = count_sink_paths(model, node.name)
    let policy_count = count_policies_for_node(model, node.name)
    let control = node.kind == Sanitizer || node.kind == Boundary
    let impact_score = from_sources * to_sinks +
      policy_count * 3 +
      (if control { 5 } else { 0 })
    result.push({
      node: node.name,
      kind: node_kind_name(node.kind),
      paths_from_sources: from_sources,
      paths_to_sinks: to_sinks,
      policy_count,
      is_control_point: control,
      impact_score,
    })
  }
  sort_impacts(result)
  result
}

///|
pub fn find_nodes_by_text(model : Model, query : String) -> Array[Node] {
  let result : Array[Node] = []
  for node in model.nodes {
    if contains_text(node.name, query) || contains_text(node.description, query) {
      result.push(node)
    }
  }
  result
}

///|
pub fn nodes_for_policy(model : Model, policy_index : Int) -> Array[String] {
  if policy_index < 0 || policy_index >= model.policies.length() {
    return []
  }
  let result : Array[String] = []
  let policy = model.policies[policy_index]
  for name in policy.path {
    if !result.contains(name) {
      result.push(name)
    }
  }
  if policy.through != "" && !result.contains(policy.through) {
    result.push(policy.through)
  }
  result
}

///|
pub fn query_policy_impact(model : Model, node_name : String) -> Array[Policy] {
  let result : Array[Policy] = []
  for policy in model.policies {
    if path_contains(policy.path, node_name) || policy.through == node_name {
      result.push(policy)
    }
  }
  result
}

///|
pub fn query_source_sink_pairs(model : Model) -> Array[(String, String)] {
  let result : Array[(String, String)] = []
  let sources = graph_node_names_by_kind(model, Source)
  let sinks = graph_node_names_by_kind(model, Sink)
  for source in sources {
    for sink in sinks {
      if has_path(model, source, sink) {
        result.push((source, sink))
      }
    }
  }
  result
}

///|
pub fn query_reachable_nodes(model : Model, start : String) -> Array[String] {
  let result : Array[String] = []
  let queue : Array[String] = [start]
  for ;; {
    if queue.length() == 0 {
      break
    }
    let current = queue.remove(0)
    if result.contains(current) {
      continue
    }
    result.push(current)
    for edge in model.edges {
      if edge.from == current && !result.contains(edge.to) {
        queue.push(edge.to)
      }
    }
  }
  result
}

///|
fn count_source_paths(model : Model, target : String) -> Int {
  let mut count = 0
  for source in graph_node_names_by_kind(model, Source) {
    if has_path(model, source, target) {
      count += 1
    }
  }
  count
}

///|
fn count_sink_paths(model : Model, start : String) -> Int {
  let mut count = 0
  for sink in graph_node_names_by_kind(model, Sink) {
    if has_path(model, start, sink) {
      count += 1
    }
  }
  count
}

///|
fn count_policies_for_node(model : Model, node_name : String) -> Int {
  let mut count = 0
  for policy in model.policies {
    if path_contains(policy.path, node_name) || policy.through == node_name {
      count += 1
    }
  }
  count
}

///|
fn contains_text(text : String, query : String) -> Bool {
  if query == "" {
    return true
  }
  text.contains(query)
}

///|
fn sort_impacts(items : Array[NodeImpact]) -> Unit {
  let mut index = 0
  while index < items.length() {
    let mut best = index
    let mut candidate = index + 1
    while candidate < items.length() {
      if items[candidate].impact_score > items[best].impact_score {
        best = candidate
      }
      candidate += 1
    }
    if best != index {
      let current = items[index]
      items[index] = items[best]
      items[best] = current
    }
    index += 1
  }
}
