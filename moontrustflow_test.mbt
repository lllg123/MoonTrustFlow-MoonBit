///|
fn model_ok(input : String) -> @moontrustflow.Model {
  match @moontrustflow.parse_model(input) {
    Ok(model) => model
    Err(err) =>
      abort("unexpected model error: " + @moontrustflow.format_error(err))
  }
}

///|
fn webapp_taint_fixture() -> String {
  "source request_body \"external input\"\n" +
  "boundary service_layer \"application service\"\n" +
  "sanitizer html_escape \"html output encoding\"\n" +
  "sanitizer sql_params \"parameterized queries\"\n" +
  "sink html_renderer \"html response renderer\"\n" +
  "sink raw_sql_exec \"legacy sql execution\"\n" +
  "edge request_body -> service_layer \"ingress\"\n" +
  "edge service_layer -> html_renderer \"template render\"\n" +
  "edge service_layer -> html_escape \"sanitize html\"\n" +
  "edge html_escape -> html_renderer \"safe html\"\n" +
  "edge service_layer -> raw_sql_exec \"legacy query\"\n" +
  "edge service_layer -> sql_params \"parameter builder\"\n" +
  "edge sql_params -> raw_sql_exec \"safe query\"\n" +
  "deny request_body -> raw_sql_exec severity=high \"raw request data must not reach SQL execution\"\n" +
  "require request_body -> raw_sql_exec through=sql_params severity=medium \"database writes must go through query parameters\"\n" +
  "require request_body -> html_renderer through=html_escape severity=medium \"html output must be escaped\"\n" +
  "allow request_body -> service_layer -> sql_params -> raw_sql_exec \"reviewed parameterized query path\""
}

///|
fn cyclic_reviewed_fixture() -> String {
  "source user_input \"browser input\"\n" +
  "node cache \"temporary cache\"\n" +
  "node worker \"background worker\"\n" +
  "sanitizer validator \"validation checkpoint\"\n" +
  "sink sink_api \"dangerous side effect\"\n" +
  "edge user_input -> cache \"seed\"\n" +
  "edge cache -> worker \"fan out\"\n" +
  "edge worker -> cache \"retry loop\"\n" +
  "edge worker -> validator \"validated branch\"\n" +
  "edge validator -> sink_api \"safe call\"\n" +
  "edge cache -> sink_api \"legacy shortcut\"\n" +
  "deny user_input -> sink_api severity=high \"direct user input must not reach side effects\"\n" +
  "allow user_input -> cache -> worker -> validator -> sink_api \"validated worker path\""
}

///|
fn branching_fixture() -> String {
  "source api_body \"request body\"\n" +
  "boundary orchestration \"service orchestration\"\n" +
  "sanitizer audit_masker \"audit masking\"\n" +
  "sanitizer html_escape \"html encoding\"\n" +
  "sanitizer queue_validator \"queue schema validation\"\n" +
  "sink audit_log \"audit sink\"\n" +
  "sink html_renderer \"html sink\"\n" +
  "sink internal_queue \"queue sink\"\n" +
  "sink metrics_export \"metrics sink\"\n" +
  "edge api_body -> orchestration \"ingress\"\n" +
  "edge orchestration -> audit_log \"audit direct\"\n" +
  "edge orchestration -> audit_masker \"audit safe\"\n" +
  "edge audit_masker -> audit_log \"audit masked\"\n" +
  "edge orchestration -> html_renderer \"render direct\"\n" +
  "edge orchestration -> html_escape \"render safe\"\n" +
  "edge html_escape -> html_renderer \"render encoded\"\n" +
  "edge orchestration -> internal_queue \"queue direct\"\n" +
  "edge orchestration -> queue_validator \"queue safe\"\n" +
  "edge queue_validator -> internal_queue \"queue validated\"\n" +
  "edge orchestration -> metrics_export \"metrics direct\"\n" +
  "require api_body -> audit_log through=audit_masker severity=medium \"audit output must be masked\"\n" +
  "require api_body -> html_renderer through=html_escape severity=medium \"html output must be escaped\"\n" +
  "require api_body -> internal_queue through=queue_validator severity=medium \"queue writes must be validated\"\n" +
  "deny api_body -> metrics_export severity=low \"raw payloads should not reach metrics\"\n" +
  "allow api_body -> orchestration -> audit_masker -> audit_log \"masked audit path\"\n" +
  "allow api_body -> orchestration -> html_escape -> html_renderer \"escaped html path\"\n" +
  "allow api_body -> orchestration -> queue_validator -> internal_queue \"validated queue path\""
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

///|
test "format report json is stable" {
  let model = model_ok(
    "source request_body \"external input\"\n" +
    "sink render_html \"html renderer\"\n" +
    "edge request_body -> render_html \"direct render\"\n" +
    "deny request_body -> render_html severity=high \"raw input must not render directly\"",
  )
  assert_eq(
    @moontrustflow.format_report_json(@moontrustflow.analyze(model)),
    "[\n  {\n    \"severity\": \"high\",\n    \"rule\": \"deny\",\n    \"source\": \"request_body\",\n    \"sink\": \"render_html\",\n    \"path\": [\n      \"request_body\",\n      \"render_html\"\n    ],\n    \"message\": \"raw input must not render directly\",\n    \"suggestion\": \"review or allow this path explicitly\"\n  }\n]",
  )
}

///|
test "complex fixture captures multi path and allow semantics" {
  let model = model_ok(webapp_taint_fixture())
  let findings = @moontrustflow.analyze(model)
  assert_eq(findings.length(), 3)
  assert_eq(
    findings[0].path.join(" -> "),
    "request_body -> service_layer -> raw_sql_exec",
  )
  assert_eq(
    findings[1].path.join(" -> "),
    "request_body -> service_layer -> raw_sql_exec",
  )
  assert_eq(
    findings[2].path.join(" -> "),
    "request_body -> service_layer -> html_renderer",
  )
}

///|
test "cycle fixture stays finite and reports only unsafe path" {
  let model = model_ok(cyclic_reviewed_fixture())
  let findings = @moontrustflow.analyze(model)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].path.join(" -> "), "user_input -> cache -> sink_api")
}

///|
test "branching fixture reports multiple unsafe leaves" {
  let model = model_ok(branching_fixture())
  let findings = @moontrustflow.analyze(model)
  assert_eq(findings.length(), 4)
}
