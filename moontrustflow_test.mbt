///|
fn model_ok(input : String) -> @moontrustflow.Model {
  match @moontrustflow.parse_model(input) {
    Ok(model) => model
    Err(err) =>
      abort("unexpected model error: " + @moontrustflow.format_error(err))
  }
}

///|
test "parse boundary nodes and allow rules" {
  let model = model_ok(
    "source request_body \"external input\"\n" +
    "boundary api_gateway \"trusted boundary\"\n" +
    "sanitizer escape_html \"html encoding\"\n" +
    "sink render_html \"html renderer\"\n" +
    "edge request_body -> api_gateway \"ingress\"\n" +
    "edge api_gateway -> escape_html \"encode\"\n" +
    "edge escape_html -> render_html \"safe render\"\n" +
    "allow request_body -> api_gateway -> escape_html -> render_html \"documented path\"",
  )
  assert_eq(model.nodes.length(), 4)
  assert_eq(model.edges.length(), 3)
  assert_eq(model.policies.length(), 1)
  assert_eq(@moontrustflow.node_kind_name(model.nodes[1].kind), "boundary")
  assert_eq(@moontrustflow.rule_kind_name(model.policies[0].kind), "allow")
}

///|
test "parse deny severity and require through policies" {
  let model = model_ok(
    "source request_body \"external input\"\n" +
    "sink render_html \"html renderer\"\n" +
    "deny request_body -> render_html severity=high \"raw render is forbidden\"\n" +
    "require request_body -> render_html through=escape_html severity=medium \"html output must be encoded\"",
  )
  assert_eq(model.policies.length(), 2)
  assert_eq(@moontrustflow.rule_kind_name(model.policies[0].kind), "deny")
  assert_eq(model.policies[0].severity, "high")
  assert_eq(@moontrustflow.rule_kind_name(model.policies[1].kind), "require")
  assert_eq(model.policies[1].through, "escape_html")
  assert_eq(model.policies[1].severity, "medium")
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
  match @moontrustflow.parse_model("edge request_body render_html") {
    Err(err) =>
      assert_eq(
        @moontrustflow.format_error(err),
        "line 1, column 19: missing arrow",
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
      "source request_body \"request\"\nsource request_body \"duplicate\"",
    ) {
    Err(err) =>
      assert_eq(
        @moontrustflow.format_error(err),
        "line 2, column 8: duplicate node request_body",
      )
    Ok(_) => abort("expected duplicate node")
  }
}

///|
test "deny policy reports matching direct path" {
  let model = model_ok(
    "source request_body \"external input\"\n" +
    "sink render_html \"html renderer\"\n" +
    "edge request_body -> render_html \"direct render\"\n" +
    "deny request_body -> render_html severity=high \"raw input must not render directly\"",
  )
  let findings = @moontrustflow.analyze(model)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].severity, "high")
  assert_eq(findings[0].rule, "deny")
  assert_eq(findings[0].path.join(" -> "), "request_body -> render_html")
}

///|
test "require policy reports paths that miss control point" {
  let model = model_ok(
    "source request_body \"external input\"\n" +
    "sanitizer escape_html \"html encoding\"\n" +
    "sink render_html \"html renderer\"\n" +
    "edge request_body -> render_html \"direct render\"\n" +
    "edge request_body -> escape_html \"encode\"\n" +
    "edge escape_html -> render_html \"safe render\"\n" +
    "require request_body -> render_html through=escape_html severity=medium \"html output must be encoded\"",
  )
  let findings = @moontrustflow.analyze(model)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].rule, "require")
  assert_eq(findings[0].path.join(" -> "), "request_body -> render_html")
}

///|
test "allow rule suppresses exact path" {
  let model = model_ok(
    "source request_body \"external input\"\n" +
    "sink render_html \"html renderer\"\n" +
    "edge request_body -> render_html \"legacy exception\"\n" +
    "deny request_body -> render_html severity=high \"raw render is forbidden\"\n" +
    "allow request_body -> render_html \"temporary exception\"",
  )
  assert_eq(@moontrustflow.analyze(model).length(), 0)
}

///|
test "reports stable ordering for multiple policies" {
  let model = model_ok(
    "source request_body \"external input\"\n" +
    "boundary api_gateway \"trusted boundary\"\n" +
    "sink render_html \"html renderer\"\n" +
    "sink audit_log \"audit output\"\n" +
    "edge request_body -> api_gateway \"ingress\"\n" +
    "edge api_gateway -> render_html \"html response\"\n" +
    "edge request_body -> audit_log \"audit event\"\n" +
    "deny request_body -> render_html severity=high \"raw render is forbidden\"\n" +
    "deny request_body -> audit_log severity=low \"audit path needs review\"",
  )
  let findings = @moontrustflow.analyze(model)
  assert_eq(findings.length(), 2)
  assert_eq(
    findings[0].path.join(" -> "),
    "request_body -> api_gateway -> render_html",
  )
  assert_eq(findings[1].path.join(" -> "), "request_body -> audit_log")
}

///|
test "format report is stable" {
  let model = model_ok(
    "source request_body \"external input\"\n" +
    "sink render_html \"html renderer\"\n" +
    "edge request_body -> render_html \"direct render\"\n" +
    "deny request_body -> render_html severity=high \"raw input must not render directly\"",
  )
  let report = @moontrustflow.format_report(@moontrustflow.analyze(model))
  assert_eq(
    report, "findings=1\n[high] deny violated: request_body -> render_html | raw input must not render directly | suggestion=review or allow this path explicitly",
  )
}
