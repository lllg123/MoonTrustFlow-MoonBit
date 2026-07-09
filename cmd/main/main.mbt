///|
fn render_text_report(
  source_label : String,
  model : @trustflow.Model,
  findings : Array[@trustflow.Finding],
) -> Unit {
  println("MoonTrustFlow policy evaluation")
  println("source=\{source_label}")
  println(
    "nodes=\{model.nodes.length()}, edges=\{model.edges.length()}, policies=\{model.policies.length()}, findings=\{findings.length()}",
  )
  for finding in findings {
    println(@trustflow.format_finding(finding))
  }
}

///|
fn parse_cli_json_flag(args : Array[String]) -> Bool {
  for arg in args {
    if arg == "--json" || arg == "-j" {
      return true
    }
  }
  false
}

///|
fn select_model_input() -> (String, String) {
  match @env.get_env_var("MOONTRUSTFLOW_MODEL_TEXT") {
    Some(model_text) if model_text != "" =>
      (
        model_text,
        match @env.get_env_var("MOONTRUSTFLOW_SOURCE_LABEL") {
          Some(label) if label != "" => label
          _ => "env:MOONTRUSTFLOW_MODEL_TEXT"
        },
      )
    _ => (@trustflow.sample_model_text(), "embedded-sample")
  }
}

///|
fn render_json_report(
  source_label : String,
  model : @trustflow.Model,
  findings : Array[@trustflow.Finding],
) -> Unit {
  let payload : Map[String, Json] = {
    "source": source_label.to_json(),
    "nodes": model.nodes.to_json(),
    "edges": model.edges.to_json(),
    "policies": model.policies.to_json(),
    "findings": findings.to_json(),
    "summary": {
      "node_count": model.nodes.length(),
      "edge_count": model.edges.length(),
      "policy_count": model.policies.length(),
      "finding_count": findings.length(),
    }.to_json(),
  }
  println(payload.to_json().stringify(indent=2))
}

///|
fn report_from_model(
  source_label : String,
  model : @trustflow.Model,
  as_json : Bool,
) -> Unit {
  let findings = @trustflow.analyze(model)
  if as_json {
    render_json_report(source_label, model, findings)
  } else {
    render_text_report(source_label, model, findings)
  }
}

///|
fn main {
  let as_json = parse_cli_json_flag(@env.args())
  let (model_text, source_label) = select_model_input()
  match @trustflow.parse_model(model_text) {
    Ok(model) => report_from_model(source_label, model, as_json)
    Err(err) => {
      let message = @trustflow.format_error(err)
      if as_json {
        println(
          { "error": message, "source": source_label }
          .to_json()
          .stringify(indent=2),
        )
      } else {
        println("model error: " + message)
      }
    }
  }
}
