///|
fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\t'
}

///|
fn starts_with(text : String, prefix : String) -> Bool {
  if text.length() < prefix.length() {
    return false
  }
  let text_chars = text.iter().to_array()
  let prefix_chars = prefix.iter().to_array()
  for i in 0..<prefix_chars.length() {
    if text_chars[i] != prefix_chars[i] {
      return false
    }
  }
  true
}

///|
fn strip_prefix(text : String, prefix : String) -> String {
  let chars = text.iter().to_array()
  let out = StringBuilder()
  for i in prefix.length()..<chars.length() {
    out.write_char(chars[i])
  }
  out.to_string()
}

///|
fn tokenize(
  text : String,
  line_number : Int,
) -> Result[Array[String], TrustFlowError] {
  let chars = text.iter().to_array()
  let tokens : Array[String] = []
  let mut i = 0
  while i < chars.length() {
    while i < chars.length() && is_space(chars[i]) {
      i += 1
    }
    if i >= chars.length() {
      continue
    }
    if chars[i] == '#' {
      return Ok(tokens)
    }
    let token = StringBuilder()
    if chars[i] == '"' {
      let quote_pos = { line: line_number, column: i + 1 }
      i += 1
      let mut closed = false
      while i < chars.length() && !closed {
        if chars[i] == '\\' && i + 1 < chars.length() {
          token.write_char(chars[i + 1])
          i += 2
        } else if chars[i] == '"' {
          closed = true
          i += 1
        } else {
          token.write_char(chars[i])
          i += 1
        }
      }
      if !closed {
        return Err(UnterminatedQuote(quote_pos))
      }
    } else {
      while i < chars.length() && !is_space(chars[i]) {
        token.write_char(chars[i])
        i += 1
      }
    }
    tokens.push(token.to_string())
  }
  Ok(tokens)
}
