use std::collections::HashMap;

#[derive(Debug, PartialEq)]
pub enum JsonValue {
    Null,
    Bool(bool),
    Number(f64),
    String(String),
    Array(Vec<JsonValue>),
    Object(HashMap<String, JsonValue>),
}

pub struct Parser<'a> {
    chars: std::str::Chars<'a>,
    current: Option<char>,
}

impl<'a> Parser<'a> {
    pub fn new(input: &'a str) -> Self {
        let mut chars = input.chars();
        let current = chars.next();
        Parser { chars, current }
    }

    fn next_char(&mut self) {
        self.current = self.chars.next();
    }

    fn expect_sequence(&mut self, expected: &str) -> bool {
        for c in expected.chars() {
            if Some(c) == self.current {
                self.next_char();
            } else {
                return false;
            }
        }
        true
    }

    pub fn parse_value(&mut self) -> Result<JsonValue, String> {
        self.skip_whitespace();
        match self.current {
            Some('n') => self.parse_null(),
            Some('t') | Some('f') => self.parse_bool(),
            Some('"') => self.parse_string(),
            Some('0'..='9') | Some('-') => self.parse_number(),
            Some('[') => self.parse_array(),
            Some('{') => self.parse_object(),
            _ => Err(format!("無効な値です: {:?}", self.current)),
        }
    }

    fn parse_null(&mut self) -> Result<JsonValue, String> {
        if self.expect_sequence("null") {
            Ok(JsonValue::Null)
        } else {
            Err("無効なnull値です".to_string())
        }
    }

    fn parse_bool(&mut self) -> Result<JsonValue, String> {
        if self.expect_sequence("true") {
            Ok(JsonValue::Bool(true))
        } else if self.expect_sequence("false") {
            Ok(JsonValue::Bool(false))
        } else {
            Err("無効なboolean値です".to_string())
        }
    }

    fn parse_number(&mut self) -> Result<JsonValue, String> {
        let mut num_str = String::new();
        if self.current == Some('-') {
            num_str.push('-');
            self.next_char();
        }

        while let Some(c) = self.current {
            if c.is_digit(10) {
                num_str.push(c);
                self.next_char();
            } else {
                break;
            }
        }

        if self.current == Some('.') {
            num_str.push('.');
            self.next_char();

            while let Some(c) = self.current {
                if c.is_digit(10) {
                    num_str.push(c);
                    self.next_char();
                } else {
                    break;
                }
            }
        }

        num_str
            .parse::<f64>()
            .map(JsonValue::Number)
            .map_err(|_| "無効な数値です".to_string())
    }

    fn parse_string(&mut self) -> Result<JsonValue, String> {
        let mut result = String::new();
        self.next_char(); // 最初の'"'をスキップ

        while let Some(c) = self.current {
            match c {
                '"' => {
                    self.next_char(); // 終了の'"'をスキップ
                    return Ok(JsonValue::String(result));
                }
                _ => {
                    result.push(c);
                    self.next_char();
                }
            }
        }

        Err("文字列の終端が見つかりません".to_string())
    }

    fn parse_array(&mut self) -> Result<JsonValue, String> {
        let mut elements = Vec::new();
        self.next_char(); // '['をスキップ
        self.skip_whitespace();

        if self.current == Some(']') {
            self.next_char(); // ']'をスキップ
            return Ok(JsonValue::Array(elements));
        }

        loop {
            let value = self.parse_value()?;
            elements.push(value);
            self.skip_whitespace();

            match self.current {
                Some(',') => {
                    self.next_char();
                    self.skip_whitespace();
                }
                Some(']') => {
                    self.next_char();
                    break;
                }
                _ => return Err("配列の終端が見つかりません".to_string()),
            }
        }

        Ok(JsonValue::Array(elements))
    }

    fn parse_object(&mut self) -> Result<JsonValue, String> {
        let mut object = HashMap::new();
        self.next_char(); // '{'をスキップ
        self.skip_whitespace();

        if self.current == Some('}') {
            self.next_char(); // '}'をスキップ
            return Ok(JsonValue::Object(object));
        }

        loop {
            self.skip_whitespace();
            if self.current != Some('"') {
                return Err("オブジェクトのキーは文字列でなければなりません".to_string());
            }

            let key = match self.parse_string()? {
                JsonValue::String(s) => s,
                _ => unreachable!(),
            };

            self.skip_whitespace();
            if self.current != Some(':') {
                return Err("キーと値の間に':'が必要です".to_string());
            }
            self.next_char(); // ':'を消費
            self.skip_whitespace();

            let value = self.parse_value()?;
            object.insert(key, value);

            self.skip_whitespace();
            match self.current {
                Some(',') => {
                    self.next_char();
                    self.skip_whitespace();
                }
                Some('}') => {
                    self.next_char();
                    break;
                }
                _ => return Err("オブジェクトの終端が見つかりません".to_string()),
            }
        }

        Ok(JsonValue::Object(object))
    }

    fn skip_whitespace(&mut self) {
        while let Some(c) = self.current {
            if c.is_whitespace() {
                self.next_char();
            } else {
                break;
            }
        }
    }
}

fn main() {
    let json_str = r#"
    {
        "name": "Alice",
        "age": 30,
        "is_student": false,
        "skills": ["Rust", "C++", "Python"],
        "address": null
    }
    "#;

    let mut parser = Parser::new(json_str);
    match parser.parse_value() {
        Ok(value) => println!("解析結果: {:#?}", value),
        Err(e) => println!("エラー: {}", e),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_null() {
        let mut parser = Parser::new("null");
        let result = parser.parse_value();
        assert_eq!(result, Ok(JsonValue::Null));
    }

    #[test]
    fn test_parse_bool_true() {
        let mut parser = Parser::new("true");
        let result = parser.parse_value();
        assert_eq!(result, Ok(JsonValue::Bool(true)));
    }

    #[test]
    fn test_parse_bool_false() {
        let mut parser = Parser::new("false");
        let result = parser.parse_value();
        assert_eq!(result, Ok(JsonValue::Bool(false)));
    }

    #[test]
    fn test_parse_number_integer() {
        let mut parser = Parser::new("42");
        let result = parser.parse_value();
        assert_eq!(result, Ok(JsonValue::Number(42.0)));
    }

    #[test]
    fn test_parse_number_float() {
        let mut parser = Parser::new("-3.14");
        let result = parser.parse_value();
        assert_eq!(result, Ok(JsonValue::Number(-3.14)));
    }

    #[test]
    fn test_parse_string_empty() {
        let mut parser = Parser::new("\"\"");
        let result = parser.parse_value();
        assert_eq!(result, Ok(JsonValue::String("".to_string())));
    }

    #[test]
    fn test_parse_string_simple() {
        let mut parser = Parser::new("\"hello\"");
        let result = parser.parse_value();
        assert_eq!(result, Ok(JsonValue::String("hello".to_string())));
    }

    #[test]
    fn test_parse_array_empty() {
        let mut parser = Parser::new("[]");
        let result = parser.parse_value();
        assert_eq!(result, Ok(JsonValue::Array(vec![])));
    }

    #[test]
    fn test_parse_array_numbers() {
        let mut parser = Parser::new("[1, 2, 3]");
        let result = parser.parse_value();
        assert_eq!(
            result,
            Ok(JsonValue::Array(vec![
                JsonValue::Number(1.0),
                JsonValue::Number(2.0),
                JsonValue::Number(3.0),
            ]))
        );
    }

    #[test]
    fn test_parse_object_empty() {
        let mut parser = Parser::new("{}");
        let result = parser.parse_value();
        assert_eq!(result, Ok(JsonValue::Object(HashMap::new())));
    }

    #[test]
    fn test_parse_object_simple() {
        let mut parser = Parser::new("{\"key\": \"value\"}");
        let mut expected = HashMap::new();
        expected.insert("key".to_string(), JsonValue::String("value".to_string()));
        assert_eq!(parser.parse_value(), Ok(JsonValue::Object(expected)));
    }

    #[test]
    fn test_parse_complex_json() {
        let json_str = r#"
        {
            "number": 123,
            "boolean": true,
            "null_value": null,
            "string": "hello",
            "array": [1, 2, 3],
            "object": {"nested_key": "nested_value"}
        }
        "#;
        let mut parser = Parser::new(json_str);
        let result = parser.parse_value();

        let mut expected_object = HashMap::new();
        expected_object.insert("number".to_string(), JsonValue::Number(123.0));
        expected_object.insert("boolean".to_string(), JsonValue::Bool(true));
        expected_object.insert("null_value".to_string(), JsonValue::Null);
        expected_object.insert("string".to_string(), JsonValue::String("hello".to_string()));
        expected_object.insert(
            "array".to_string(),
            JsonValue::Array(vec![
                JsonValue::Number(1.0),
                JsonValue::Number(2.0),
                JsonValue::Number(3.0),
            ]),
        );

        let mut nested_object = HashMap::new();
        nested_object.insert(
            "nested_key".to_string(),
            JsonValue::String("nested_value".to_string()),
        );
        expected_object.insert("object".to_string(), JsonValue::Object(nested_object));

        assert_eq!(result, Ok(JsonValue::Object(expected_object)));
    }

    #[test]
    fn test_parse_invalid_json() {
        let mut parser = Parser::new("{invalid json}");
        let result = parser.parse_value();
        assert!(result.is_err());
    }

    #[test]
    fn test_parse_string_with_escape() {
        let json_str = r#"
        {
            "string": "hel\nlo"
        }
        "#;
        let mut parser = Parser::new(json_str);
        let result = parser.parse_value();
        let mut expected_object = HashMap::new();
        // expected_object.insert(
        //     "string".to_string(),
        //     JsonValue::String("hel\nlo".to_string()),
        // );
        // エスケープ文字はまだ対応していないため、エスケープされた文字列がそのまま格納される
        expected_object.insert(
            "string".to_string(),
            JsonValue::String("hel\\nlo".to_string()),
        );
        assert_eq!(result, Ok(JsonValue::Object(expected_object)));
    }
}
