module parsers

import regex

pub struct LuaParser {}

pub fn (p LuaParser) get_extensions() []string {
	return ['.lua']
}

pub fn (p LuaParser) parse(content string, file_path string) ParseResult {
	mut result := ParseResult{
		file_path: file_path
		elements: []CodeElement{}
	}

	lines := content.split_into_lines()
	
	for i, line in lines {
		trimmed := line.trim_space()
		
		// Skip comments
		if trimmed.starts_with('--') {
			continue
		}
		
		// Parse function definitions
		if trimmed.starts_with('function ') || trimmed.starts_with('local function ') {
			result.elements << p.parse_function(lines, i)
		}
	}

	return result
}

fn (p LuaParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut func_name := ''
	mut access := 'public'
	mut element_type := 'function'
	
	// Check for local functions
	if line.starts_with('local function ') {
		access = 'private'
	}
	
	// Extract function name (handle both function name() and function obj:method())
	mut re := regex.regex_opt(r'function\s+(?:[\w.]+[.:])?(\w+)\s*\(') or { panic(err) }
	start, _ := re.match_string(line)
	
	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			func_name = line[groups[0].start..groups[0].end]
		}
	}
	
	// Check if it's a method (uses : syntax)
	if line.contains(':') {
		element_type = 'method'
	}
	
	doc := extract_doc_lines(lines, idx, 2)
	
	return CodeElement{
		element_type: element_type
		name: func_name
		access: access
		doc: doc
		line_number: idx + 1
	}
}
