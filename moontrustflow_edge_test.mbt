///|
test "empty and disconnected models produce no findings" {
  let empty = match @moontrustflow.parse_model("# comments only\r\n\r\n") {
    Ok(model) => model
    Err(err) => abort(@moontrustflow.format_error(err))
  }
  assert_eq(empty.nodes.length(), 0)
  assert_eq(@moontrustflow.analyze(empty).length(), 0)

  let disconnected = model_ok(
    "source orphan_input \"external input\"\r\n" +
    "sink unreachable_sink \"unreachable sink\"\r\n" +
    "deny orphan_input -> unreachable_sink severity=high \"no path\"\r\n",
  )
  assert_eq(@moontrustflow.analyze(disconnected).length(), 0)
}

///|
test "quoted descriptions and CRLF input remain stable" {
  let model = model_ok(
    "source api_body \"quoted \\\"payload\\\"\"\r\n" +
    "sink render_html \"HTML renderer\"\r\n" +
    "edge api_body -> render_html \"direct response\" # comment\r\n" +
    "deny api_body -> render_html severity=high \"raw payload must not render\"\r\n",
  )
  assert_eq(model.nodes[0].description, "quoted \"payload\"")
  assert_eq(model.edges[0].label, "direct response")
  assert_eq(@moontrustflow.analyze(model).length(), 1)
}

///|
test "missing require control point is rejected" {
  match
    @moontrustflow.parse_model("require source -> sink \"missing through\"") {
    Err(err) =>
      assert_eq(
        @moontrustflow.format_error(err),
        "line 1, column 1: require policy missing through=",
      )
    Ok(_) => abort("expected missing through error")
  }
}

///|
test "default rule severities are deterministic" {
  let model = model_ok(
    "source input \"external input\"\n" +
    "sink output \"side effect\"\n" +
    "edge input -> output \"direct\"\n" +
    "deny input -> output \"blocked\"\n",
  )
  assert_eq(model.policies[0].severity, "high")
  assert_eq(@moontrustflow.analyze(model)[0].severity, "high")
}
