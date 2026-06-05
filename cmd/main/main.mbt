///|
fn main {
  let sample = "source user_input \"external request body\"\n" +
    "sanitizer escape_html \"html escaping\"\n" +
    "sink render_html \"html response renderer\"\n" +
    "sink sql_exec \"database execution\"\n" +
    "edge user_input -> render_html \"direct render\"\n" +
    "edge user_input -> escape_html \"sanitize\"\n" +
    "edge escape_html -> render_html \"safe render\"\n" +
    "edge user_input -> sql_exec \"dynamic query\"\n" +
    "allow user_input -> escape_html -> render_html"
  match @trustflow.parse_model(sample) {
    Ok(model) => {
      let findings = @trustflow.analyze(model)
      println("MoonTrustFlow demo")
      println(
        "nodes=\{model.nodes.length()}, edges=\{model.edges.length()}, findings=\{findings.length()}",
      )
      println(@trustflow.format_report(findings))
    }
    Err(err) => println("model error: " + @trustflow.format_error(err))
  }
}
