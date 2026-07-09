///|
test "inline comments are ignored after tokens" {
  let model = match
    parse_model(
      "source request_body \"request\" # real source\n" +
      "sink render_html \"renderer\"\n" +
      "edge request_body -> render_html \"direct\" # reviewed later\n" +
      "deny request_body -> render_html severity=high \"blocked\"",
    ) {
    Ok(model) => model
    Err(err) => abort(format_error(err))
  }
  assert_eq(model.nodes.length(), 2)
  assert_eq(model.edges.length(), 1)
  assert_eq(model.policies.length(), 1)
}
