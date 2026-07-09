///|
pub fn format_finding(finding : Finding) -> String {
  "[\{finding.severity}] \{finding.rule} violated: \{finding.path.join(" -> ")} | \{finding.message} | suggestion=\{finding.suggestion}"
}

///|
pub fn format_report(findings : Array[Finding]) -> String {
  let out = StringBuilder()
  out.write_string("findings=\{findings.length()}")
  for finding in findings {
    out.write_char('\n')
    out.write_string(format_finding(finding))
  }
  out.to_string()
}

///|
pub fn format_report_json(findings : Array[Finding]) -> String {
  findings.to_json().stringify(indent=2)
}
