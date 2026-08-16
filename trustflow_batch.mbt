///|
pub(all) struct BatchInput {
  source : String
  text : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct BatchItem {
  source : String
  parsed : Bool
  finding_count : Int
  risk_score : Int
  risk_band : String
  error : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct BatchSummary {
  total_models : Int
  parsed_models : Int
  failed_models : Int
  finding_count : Int
  high_finding_count : Int
  medium_finding_count : Int
  low_finding_count : Int
  average_risk_score : Int
  maximum_risk_score : Int
} derive(Eq, Debug, ToJson)

///|
pub(all) struct BatchReport {
  items : Array[BatchItem]
  summary : BatchSummary
} derive(Eq, Debug, ToJson)

///|
pub fn analyze_batch(inputs : Array[BatchInput]) -> BatchReport {
  let items : Array[BatchItem] = []
  let mut parsed_models = 0
  let mut failed_models = 0
  let mut finding_count = 0
  let mut high_count = 0
  let mut medium_count = 0
  let mut low_count = 0
  let mut total_risk = 0
  let mut maximum_risk = 0
  for input in inputs {
    match parse_model(input.text) {
      Ok(model) => {
        parsed_models += 1
        let findings = analyze(model)
        let assessment = assess_model(model)
        finding_count += findings.length()
        total_risk += assessment.risk_score
        if assessment.risk_score > maximum_risk {
          maximum_risk = assessment.risk_score
        }
        for finding in findings {
          match finding.severity {
            "high" => high_count += 1
            "medium" => medium_count += 1
            _ => low_count += 1
          }
        }
        items.push({
          source: input.source,
          parsed: true,
          finding_count: findings.length(),
          risk_score: assessment.risk_score,
          risk_band: risk_band_name(assessment.risk_band),
          error: "",
        })
      }
      Err(error) => {
        failed_models += 1
        items.push({
          source: input.source,
          parsed: false,
          finding_count: 0,
          risk_score: 100,
          risk_band: "critical",
          error: format_error(error),
        })
      }
    }
  }
  let average_risk_score = if parsed_models == 0 {
    0
  } else {
    total_risk / parsed_models
  }
  {
    items,
    summary: {
      total_models: inputs.length(),
      parsed_models,
      failed_models,
      finding_count,
      high_finding_count: high_count,
      medium_finding_count: medium_count,
      low_finding_count: low_count,
      average_risk_score,
      maximum_risk_score: maximum_risk,
    },
  }
}

///|
pub fn batch_report_json(report : BatchReport) -> String {
  report.to_json().stringify(indent=2)
}

///|
pub fn format_batch_report(report : BatchReport) -> String {
  let out = StringBuilder()
  out.write_string("batch models=\{report.summary.total_models}")
  out.write_string(" parsed=\{report.summary.parsed_models}")
  out.write_string(" failed=\{report.summary.failed_models}")
  out.write_string(" findings=\{report.summary.finding_count}")
  out.write_string(" average_risk=\{report.summary.average_risk_score}")
  out.write_string(" max_risk=\{report.summary.maximum_risk_score}")
  for item in report.items {
    out.write_string("\n\{item.source}: ")
    if item.parsed {
      out.write_string(
        "parsed findings=\{item.finding_count} risk=\{item.risk_band}(\{item.risk_score})",
      )
    } else {
      out.write_string("parse_error=\{item.error}")
    }
  }
  out.to_string()
}

///|
pub fn batch_has_failures(report : BatchReport) -> Bool {
  report.summary.failed_models > 0
}

///|
pub fn batch_is_clean(report : BatchReport) -> Bool {
  report.summary.failed_models == 0 && report.summary.finding_count == 0
}

///|
pub fn batch_sources(report : BatchReport) -> Array[String] {
  let sources : Array[String] = []
  for item in report.items {
    sources.push(item.source)
  }
  sources
}

///|
pub fn batch_item_for(report : BatchReport, source : String) -> BatchItem? {
  for item in report.items {
    if item.source == source {
      return Some(item)
    }
  }
  None
}

///|
pub fn merge_batch_reports(
  left : BatchReport,
  right : BatchReport,
) -> BatchReport {
  let inputs : Array[BatchInput] = []
  for item in left.items {
    inputs.push({ source: item.source, text: "" })
  }
  for item in right.items {
    inputs.push({ source: item.source, text: "" })
  }
  ignore(inputs)
  let items : Array[BatchItem] = []
  for item in left.items {
    items.push(item)
  }
  for item in right.items {
    items.push(item)
  }
  { items, summary: merge_batch_summaries(left.summary, right.summary) }
}

///|
fn merge_batch_summaries(
  left : BatchSummary,
  right : BatchSummary,
) -> BatchSummary {
  let parsed = left.parsed_models + right.parsed_models
  {
    total_models: left.total_models + right.total_models,
    parsed_models: parsed,
    failed_models: left.failed_models + right.failed_models,
    finding_count: left.finding_count + right.finding_count,
    high_finding_count: left.high_finding_count + right.high_finding_count,
    medium_finding_count: left.medium_finding_count + right.medium_finding_count,
    low_finding_count: left.low_finding_count + right.low_finding_count,
    average_risk_score: if parsed == 0 {
      0
    } else {
      (
        left.average_risk_score * left.parsed_models +
        right.average_risk_score * right.parsed_models
      ) /
      parsed
    },
    maximum_risk_score: if left.maximum_risk_score > right.maximum_risk_score {
      left.maximum_risk_score
    } else {
      right.maximum_risk_score
    },
  }
}
