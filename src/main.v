module main

import os
import flag

struct Arguments {
mut:
	input   string
	lang    string
	output  string
	config  string
	verbose bool
	help    bool
}

fn main() {
	args := parse_arguments()

	if args.help {
		print_help()
		exit(0)
	}

	// Validate required arguments
	if args.input.len == 0 {
		eprintln('Error: --input is required')
		print_help()
		exit(1)
	}

	if !os.exists(args.input) {
		eprintln('Error: Input path does not exist: ${args.input}')
		exit(1)
	}

	if !os.is_dir(args.input) {
		eprintln('Error: Input path must be a directory: ${args.input}')
		exit(1)
	}

	// Load config if provided
	if args.config.len > 0 {
		config := load_config(args.config) or {
			eprintln('Error loading config: ${err}')
			exit(1)
		}
		if args.verbose {
			eprintln('Loaded config with ${config.custom_languages.len} custom language(s)')
		}
	}

	// Initialize analyzer
	mut analyzer := new_analyzer()
	if args.lang.len > 0 {
		analyzer.target_lang = args.lang
	}

	// Initialize progress tracker
	mut progress := ProgressTracker{}
	progress.init(args.verbose, 0)

	if args.verbose {
		eprintln('Starting analysis of: ${args.input}')
		extensions := analyzer.get_supported_extensions()
		eprintln('Supported extensions: ${extensions.join(', ')}')
	}

	// Analyze directory
	results := analyzer.analyze_directory(args.input, mut progress)

	// Write output
	write_output(results, args.output) or {
		eprintln('Error writing output: ${err}')
		exit(1)
	}

	// Print summary
	progress.print_summary()

	if args.verbose {
		eprintln('Output written to: ${args.output}')
	}

	exit(0)
}

fn parse_arguments() Arguments {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('code-analyzer')
	fp.version('v1.0.0')
	fp.description('Code Structure Analyzer - recursively analyzes source code directories')
	fp.skip_executable()

	mut args := Arguments{}

	args.input = fp.string('input', `i`, '', 'Root directory path (required)')
	args.lang = fp.string('lang', `l`, '', 'Programming language filter (optional)')
	args.output = fp.string('output', `o`, './output.txt', 'Output file path')
	args.config = fp.string('config', `c`, '', 'Custom config file path')
	args.verbose = fp.bool('verbose', `v`, false, 'Show progress and details')
	args.help = fp.bool('help', `h`, false, 'Show help message')

	fp.finalize() or {
		eprintln('Error parsing arguments: ${err}')
		print_help()
		exit(1)
	}

	return args
}

fn print_help() {
	help_text := '
Code Analyzer - Code Structure Analyzer

Usage:
  code-analyzer --input <path> [options]

Arguments:
  -i, --input <path>      Root directory path (required)
  -l, --lang <language>   Programming language filter (optional)
  -o, --output <file>     Output file path (default: ./output.txt)
  -c, --config <file>     Custom config file path (YAML or JSON)
  -v, --verbose           Show progress and details
  -h, --help              Show this help message

Supported Languages:
  - Java (.java)
  - JavaScript (.js, .jsx)
  - TypeScript (.ts, .tsx)
  - Dart (.dart)
  - Rust (.rs)
  - C++ (.cpp, .cc, .cxx, .hpp, .h, .hxx)
  - Python (.py)
  - C# (.cs)
  - V (Vlang) (.v, .vv)
  - C (.c)
  - D (.d)
  - Lua (.lua)
  - Pascal (.pas, .pp, .inc)
  - Swift (.swift)
  - Ruby (.rb)
  - Go (.go)
  - Kotlin
  - Scala
  - PHP
  - Zig
  
Examples:
  # Analyze a Python project
  code-analyzer --input ./my-project --lang python --output results.txt

  # Analyze all supported languages with verbose output
  code-analyzer --input ./src --verbose

  # Use custom config for additional languages
  code-analyzer --input ./src --config ./custom.yaml --verbose
'
	println(help_text)
}
