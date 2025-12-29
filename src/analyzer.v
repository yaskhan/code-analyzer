module main

import os
import parsers

pub struct Analyzer {
pub mut:
    parsers_map map[string]parsers.Parser
    target_lang string
}

pub fn new_analyzer() Analyzer {
    mut a := Analyzer{}
    a.register_parsers()
    return a
}

fn (mut a Analyzer) register_parsers() {
    // Register all built-in parsers
    python_parser := parsers.PythonParser{}
    for ext in python_parser.get_extensions() {
        a.parsers_map[ext] = python_parser
    }

    js_ts_parser := parsers.JsTsParser{}
    for ext in js_ts_parser.get_extensions() {
        a.parsers_map[ext] = js_ts_parser
    }

    java_parser := parsers.JavaParser{}
    for ext in java_parser.get_extensions() {
        a.parsers_map[ext] = java_parser
    }

    rust_parser := parsers.RustParser{}
    for ext in rust_parser.get_extensions() {
        a.parsers_map[ext] = rust_parser
    }

    cpp_parser := parsers.CppParser{}
    for ext in cpp_parser.get_extensions() {
        a.parsers_map[ext] = cpp_parser
    }

    csharp_parser := parsers.CSharpParser{}
    for ext in csharp_parser.get_extensions() {
        a.parsers_map[ext] = csharp_parser
    }

    dart_parser := parsers.DartParser{}
    for ext in dart_parser.get_extensions() {
        a.parsers_map[ext] = dart_parser
    }

    c_parser := parsers.CParser{}
    for ext in c_parser.get_extensions() {
        a.parsers_map[ext] = c_parser
    }

    d_parser := parsers.DParser{}
    for ext in d_parser.get_extensions() {
        a.parsers_map[ext] = d_parser
    }

    lua_parser := parsers.LuaParser{}
    for ext in lua_parser.get_extensions() {
        a.parsers_map[ext] = lua_parser
    }

    pascal_parser := parsers.PascalParser{}
    for ext in pascal_parser.get_extensions() {
        a.parsers_map[ext] = pascal_parser
    }

    swift_parser := parsers.SwiftParser{}
    for ext in swift_parser.get_extensions() {
        a.parsers_map[ext] = swift_parser
    }

    ruby_parser := parsers.RubyParser{}
    for ext in ruby_parser.get_extensions() {
        a.parsers_map[ext] = ruby_parser
    }

    go_parser := parsers.GoParser{}
    for ext in go_parser.get_extensions() {
        a.parsers_map[ext] = go_parser
    }

    vlang_parser := parsers.VlangParser{}
    for ext in vlang_parser.get_extensions() {
        a.parsers_map[ext] = vlang_parser
    }

    kotlin_parser := parsers.KotlinParser{}
    for ext in kotlin_parser.get_extensions() {
        a.parsers_map[ext] = kotlin_parser
    }

    scala_parser := parsers.ScalaParser{}
    for ext in scala_parser.get_extensions() {
        a.parsers_map[ext] = scala_parser
    }

    php_parser := parsers.PhpParser{}
    for ext in php_parser.get_extensions() {
        a.parsers_map[ext] = php_parser
    }

    zig_parser := parsers.ZigParser{}
    for ext in zig_parser.get_extensions() {
        a.parsers_map[ext] = zig_parser
    }
}

pub fn (mut a Analyzer) analyze_directory(root_path string, mut progress ProgressTracker) []parsers.ParseResult {
    mut results := []parsers.ParseResult{}
    
    // Get all files to process
    files := a.collect_files(root_path)
    progress.total_files = files.len
    
    for file_path in files {
        progress.report_file(file_path)
        
        result := a.analyze_file(file_path) or {
            progress.report_error(file_path, err.msg())
            continue
        }
        
        if result.elements.len > 0 {
            results << result
        }
    }
    
    return results
}

fn (a Analyzer) collect_files(root_path string) []string {
    mut files := []string{}
    a.walk_directory(root_path, mut files)
    return files
}

fn (a Analyzer) walk_directory(dir_path string, mut files []string) {
    entries := os.ls(dir_path) or { return }
    
    for entry in entries {
        full_path := os.join_path(dir_path, entry)
        
        // Skip hidden files and directories
        if entry.starts_with('.') {
            continue
        }
        
        if os.is_dir(full_path) {
            // Recursively walk subdirectories
            a.walk_directory(full_path, mut files)
        } else if os.is_file(full_path) {
            // Check if file has supported extension
            ext := os.file_ext(full_path)
            if ext in a.parsers_map || a.target_lang.len == 0 {
                files << full_path
            }
        }
    }
}

pub fn (a Analyzer) analyze_file(file_path string) !parsers.ParseResult {
    ext := os.file_ext(file_path)
    
    parser := a.parsers_map[ext] or {
        return error('No parser found for extension: ${ext}')
    }
    
    content := os.read_file(file_path) or {
        return error('Failed to read file: ${err}')
    }
    
    return parser.parse(content, file_path)
}

pub fn (a Analyzer) get_supported_extensions() []string {
    mut extensions := []string{}
    for ext, _ in a.parsers_map {
        extensions << ext
    }
    return extensions
}
