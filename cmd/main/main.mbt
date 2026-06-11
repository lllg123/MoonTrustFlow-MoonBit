///|
fn main {
  let sample = "source request_body \"external input\"\n" +
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
  match @trustflow.parse_model(sample) {
    Ok(model) => {
      let findings = @trustflow.analyze(model)
      println("MoonTrustFlow policy evaluation")
      println(
        "nodes=\{model.nodes.length()}, edges=\{model.edges.length()}, policies=\{model.policies.length()}, findings=\{findings.length()}",
      )
      for finding in findings {
        println(@trustflow.format_finding(finding))
      }
    }
    Err(err) => println("model error: " + @trustflow.format_error(err))
  }
}
