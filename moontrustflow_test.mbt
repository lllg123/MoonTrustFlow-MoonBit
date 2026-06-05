///|
fn model_ok(input : String) -> @moontrustflow.Model {
  match @moontrustflow.parse_model(input) {
    Ok(model) => model
    Err(err) =>
      abort("unexpected model error: " + @moontrustflow.format_error(err))
  }
}

///|
test "parse nodes edges and allow rules" {
  let model = model_ok(
    "source user_input \"external request body\"\n" +
    "sanitizer escape_html \"html escaping\"\n" +
    "sink render_html \"html response renderer\"\n" +
    "edge user_input -> escape_html \"sanitize\"\n" +
    "edge escape_html -> render_html \"safe render\"\n" +
    "allow user_input -> escape_html -> render_html",
  )
  assert_eq(model.nodes.length(), 3)
  assert_eq(model.edges.length(), 2)
  assert_eq(model.policies.length(), 1)
  assert_eq(@moontrustflow.node_kind_name(model.nodes[0].kind), "source")
}

///|
test "reports syntax errors with line and column" {
  match @moontrustflow.parse_model("source\n") {
    Err(err) =>
      assert_eq(
        @moontrustflow.format_error(err),
        "line 1, column 7: missing node name",
      )
    Ok(_) => abort("expected missing node name")
  }
  match @moontrustflow.parse_model("edge user_input render_html") {
    Err(err) =>
      assert_eq(
        @moontrustflow.format_error(err),
        "line 1, column 17: missing arrow",
      )
    Ok(_) => abort("expected missing arrow")
  }
  match @moontrustflow.parse_model("unknown node") {
    Err(err) =>
      assert_eq(
        @moontrustflow.format_error(err),
        "line 1, column 1: unknown directive unknown",
      )
    Ok(_) => abort("expected unknown directive")
  }
}

///|
test "reports duplicate node" {
  match
    @moontrustflow.parse_model(
      "source user_input \"request\"\nsource user_input \"duplicate\"",
    ) {
    Err(err) =>
      assert_eq(
        @moontrustflow.format_error(err),
        "line 2, column 8: duplicate node user_input",
      )
    Ok(_) => abort("expected duplicate node")
  }
}

///|
test "find direct source to sink risk" {
  let model = model_ok(
    "source user_input \"external request body\"\n" +
    "sink render_html \"html response renderer\"\n" +
    "edge user_input -> render_html \"direct render\"",
  )
  let findings = @moontrustflow.analyze(model)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].source, "user_input")
  assert_eq(findings[0].sink, "render_html")
  assert_eq(findings[0].path.join(" -> "), "user_input -> render_html")
}

///|
test "sanitizer stops taint propagation" {
  let model = model_ok(
    "source user_input \"external request body\"\n" +
    "sanitizer escape_html \"html escaping\"\n" +
    "sink render_html \"html response renderer\"\n" +
    "edge user_input -> escape_html \"sanitize\"\n" +
    "edge escape_html -> render_html \"safe render\"",
  )
  assert_eq(@moontrustflow.analyze(model).length(), 0)
}

///|
test "allow rule suppresses exact path" {
  let model = model_ok(
    "source user_input \"external request body\"\n" +
    "sink render_html \"html response renderer\"\n" +
    "edge user_input -> render_html \"legacy accepted path\"\n" +
    "allow user_input -> render_html",
  )
  assert_eq(@moontrustflow.analyze(model).length(), 0)
}

///|
test "reports multiple source to sink findings" {
  let model = model_ok(
    "source query_param \"url query\"\n" +
    "source cookie_value \"cookie\"\n" +
    "sink sql_exec \"database execution\"\n" +
    "sink shell_exec \"shell execution\"\n" +
    "edge query_param -> sql_exec \"dynamic query\"\n" +
    "edge cookie_value -> shell_exec \"shell arg\"",
  )
  let findings = @moontrustflow.analyze(model)
  assert_eq(findings.length(), 2)
  assert_eq(findings[0].path.join(" -> "), "query_param -> sql_exec")
  assert_eq(findings[1].path.join(" -> "), "cookie_value -> shell_exec")
}

///|
test "format report is stable" {
  let model = model_ok(
    "source user_input \"external request body\"\n" +
    "sink render_html \"html response renderer\"\n" +
    "edge user_input -> render_html \"direct render\"",
  )
  let report = @moontrustflow.format_report(@moontrustflow.analyze(model))
  assert_eq(
    report, "findings=1\n[high] user_input -> render_html | path=user_input -> render_html | unsanitized flow reaches dangerous sink",
  )
}
