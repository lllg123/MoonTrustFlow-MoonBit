///|
pub(all) struct SarifOptions {
  tool_name : String
  tool_version : String
  repository_uri : String
  include_help : Bool
} derive(Eq, Debug, ToJson)

///|
pub(all) struct SarifTool {
  name : String
  version : String
  information_uri : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct SarifDriver {
  name : String
  version : String
  information_uri : String
  rules : Array[SarifRule]
} derive(Eq, Debug, ToJson)

///|
pub(all) struct SarifRule {
  id : String
  name : String
  short_description : String
  help_uri : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct SarifArtifactLocation {
  uri : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct SarifLocation {
  artifact_location : SarifArtifactLocation
  logical_regions : Array[SarifRegion]
} derive(Eq, Debug, ToJson)

///|
pub(all) struct SarifRegion {
  start_line : Int
  start_column : Int
} derive(Eq, Debug, ToJson)

///|
pub(all) struct SarifMessage {
  text : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct SarifResult {
  rule_id : String
  level : String
  message : SarifMessage
  locations : Array[SarifLocation]
  fingerprints : Map[String, String]
} derive(Eq, Debug, ToJson)

///|
pub(all) struct SarifRun {
  tool : SarifToolWrapper
  results : Array[SarifResult]
} derive(Eq, Debug, ToJson)

///|
pub(all) struct SarifToolWrapper {
  driver : SarifDriver
} derive(Eq, Debug, ToJson)

///|
pub(all) struct SarifReport {
  version : String
  schema : String
  runs : Array[SarifRun]
} derive(Eq, Debug, ToJson)

///|
pub fn default_sarif_options() -> SarifOptions {
  {
    tool_name: "MoonTrustFlow",
    tool_version: "0.1.1",
    repository_uri: "https://github.com/lllg123/MoonTrustFlow-MoonBit",
    include_help: true,
  }
}

///|
pub fn format_sarif(findings : Array[Finding]) -> String {
  format_sarif_with_options(findings, default_sarif_options())
}

///|
pub fn format_sarif_with_options(
  findings : Array[Finding],
  options : SarifOptions,
) -> String {
  let rules = sarif_rules(findings, options)
  let results = sarif_results(findings, options)
  let driver : SarifDriver = {
    name: options.tool_name,
    version: options.tool_version,
    information_uri: options.repository_uri,
    rules,
  }
  let report : SarifReport = {
    version: "2.1.0",
    schema: "https://json.schemastore.org/sarif-2.1.0.json",
    runs: [{ tool: { driver, }, results }],
  }
  report.to_json().stringify(indent=2)
}

///|
fn sarif_rules(
  findings : Array[Finding],
  options : SarifOptions,
) -> Array[SarifRule] {
  let ids : Array[String] = []
  let rules : Array[SarifRule] = []
  for finding in findings {
    let id = sarif_rule_id(finding)
    if !ids.contains(id) {
      ids.push(id)
      rules.push({
        id,
        name: sarif_rule_name(finding),
        short_description: sarif_rule_name(finding),
        help_uri: if options.include_help {
          options.repository_uri + "#public-api"
        } else {
          ""
        },
      })
    }
  }
  rules
}

///|
fn sarif_results(
  findings : Array[Finding],
  options : SarifOptions,
) -> Array[SarifResult] {
  let results : Array[SarifResult] = []
  for finding in findings {
    let rule_id = sarif_rule_id(finding)
    let explanation = explain_finding(finding)
    results.push({
      rule_id,
      level: sarif_level(finding.severity),
      message: {
        text: if options.include_help {
          format_finding(finding) + " | " + explanation.summary
        } else {
          format_finding(finding)
        },
      },
      locations: [
        {
          artifact_location: { uri: "model.mtf" },
          logical_regions: [{ start_line: 1, start_column: 1 }],
        },
      ],
      fingerprints: { "moontrustflow/path": finding.path.join("->") },
    })
  }
  results
}

///|
fn sarif_rule_id(finding : Finding) -> String {
  "moontrustflow/\{finding.rule}-\{finding.severity}"
}

///|
fn sarif_rule_name(finding : Finding) -> String {
  if finding.rule == "deny" {
    "Forbidden trust-flow route"
  } else if finding.rule == "require" {
    "Missing required control point"
  } else {
    "Trust-flow policy finding"
  }
}

///|
fn sarif_level(severity : String) -> String {
  if severity == "high" {
    "error"
  } else if severity == "medium" {
    "warning"
  } else {
    "note"
  }
}
