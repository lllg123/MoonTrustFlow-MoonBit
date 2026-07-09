///|
fn max_search_depth(model : Model) -> Int {
  let budget = model.nodes.length() + model.edges.length()
  if budget < 2 {
    2
  } else {
    budget
  }
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
fn find_paths(
  model : Model,
  from : String,
  to : String,
) -> Array[Array[String]] {
  let paths : Array[Array[String]] = []
  collect_paths(model, from, to, [from], paths, max_search_depth(model))
  paths
}

///|
fn collect_paths(
  model : Model,
  current : String,
  target : String,
  path : Array[String],
  paths : Array[Array[String]],
  depth_budget : Int,
) -> Unit {
  if depth_budget <= 0 {
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
      collect_paths(model, edge.to, target, next_path, paths, depth_budget - 1)
    }
  }
}
