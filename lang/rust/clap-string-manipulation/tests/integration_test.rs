use assert_cmd::Command;
use predicates::prelude::*;

#[test]
fn test_replacement() {
    let mut cmd = Command::cargo_bin("strman").unwrap();
    cmd.arg("--replace")
        .arg("_")
        .write_stdin("This  is   a    test.")
        .assert()
        .success()
        .stdout("This_is_a_test.\n");
}

#[test]
fn test_no_whitespace() {
    let mut cmd = Command::cargo_bin("strman").unwrap();
    cmd.write_stdin("NoWhitespaceHere")
        .assert()
        .success()
        .stdout("NoWhitespaceHere\n");
}

#[test]
fn test_no_arg_value() {
    let mut cmd = Command::cargo_bin("strman").unwrap();
    cmd.arg("--replace")
        .write_stdin("This  is   a    test.")
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "a value is required for '--replace <REPLACE>' but none was supplied",
        ));
}

#[test]
fn test_uppercase() {
    let mut cmd = Command::cargo_bin("strman").unwrap();
    cmd.arg("--uppercase")
        .write_stdin("This  is   a    test.")
        .assert()
        .success()
        .stdout("THIS  IS   A    TEST.\n");
}

#[test]
fn test_replace_and_uppercase() {
    let mut cmd = Command::cargo_bin("strman").unwrap();
    cmd.arg("--replace")
        .arg("-")
        .arg("--uppercase")
        .write_stdin("This  is   a    test.")
        .assert()
        .success()
        .stdout("THIS-IS-A-TEST.\n");
}
