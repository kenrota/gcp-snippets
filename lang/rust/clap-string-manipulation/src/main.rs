use clap::{Arg, ArgAction, Command};
use regex::Regex;
use std::io::{self, Read};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Define the command line arguments
    let matches = Command::new("string-manipulation")
        .version("0.1")
        .about("Replaces multiple whitespaces with a specified character")
        .arg(
            Arg::new("replace")
                .short('r')
                .long("replace")
                .value_name("REPLACE")
                .help("Replacement string")
                .num_args(1),
        )
        .arg(
            Arg::new("uppercase")
                .short('u')
                .long("uppercase")
                .action(ArgAction::SetTrue)
                .help("Converts the output to uppercase"),
        )
        .get_matches();

    // Get the replacement string
    let replace_with = matches.get_one::<String>("replace");

    // Check if the uppercase option is set
    let to_uppercase = matches.get_flag("uppercase");

    // Read input from stdin
    let mut input = String::new();
    io::stdin()
        .read_to_string(&mut input)
        .unwrap_or_else(|err| {
            eprintln!("Failed to read from stdin: {}", err);
            std::process::exit(1);
        });

    // Replace multiple whitespaces with the specified character or keep the input as is
    let re = Regex::new(r"\s+")?;
    let mut result = replace_with
        .map(|replace| re.replace_all(&input.trim(), replace).to_string())
        .unwrap_or(input);

    // Convert to uppercase if the option is set
    if to_uppercase {
        result = result.to_uppercase();
    }

    // Output the result
    println!("{}", result);
    Ok(())
}
