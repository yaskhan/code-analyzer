module parsers

import regex

pub struct DartParser {}

pub fn (p DartParser) get_extensions() []string {
	return ['.dart']
}

pub fn (p DartParser) parse(content string, file_path string) ParseResult {
	mut result := ParseResult{
		file_path: file_path
		elements: []CodeElement{}
	}

	lines := content.split_into_lines()
	
	for i, line in lines {
		trimmed := line.trim_space()
		
		// Skip comments
		if trimmed.starts_with('//') || trimmed.starts_with('/*') {
			continue
		}
		
		// Parse class definitions
		if trimmed.contains('class ') {
			result.elements << p.parse_class(lines, i)
		}
		// Parse function/method definitions
		else if p.is_function_line(trimmed) {
			result.elements << p.parse_function(lines, i)
		}
	}

	return result
}

fn (p DartParser) is_function_line(line string) bool {
	if line.starts_with('//') || line.starts_with('/*') {
		return false
	}
	return line.contains('(') && line.contains(')') &&
	       (line.contains('void ') || line.contains('int ') || 
	        line.contains('String ') || line.contains('bool ') ||
	        line.contains('Future') || line.contains('Stream') ||
	        line.ends_with('{') || line.ends_with('=>'))
}

fn (p DartParser) parse_class(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut class_name := ''
	mut parent := ''
	
	// Extract class name and inheritance
	mut re := regex.regex_opt(r'class\s+(\w+)(?:\s+extends\s+(\w+))?') or { panic(err) }
	start, _ := re.match_string(line)
	
	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			class_name = line[groups[0].start..groups[0].end]
		}
		if groups.len > 1 && groups[1].start >= 0 {
			parent = line[groups[1].start..groups[1].end]
		}
	}
	
	doc := extract_doc_lines(lines, idx, 5)
	
	return CodeElement{
		element_type: 'class'
		name: class_name
		parent: parent
		doc: doc
		line_number: idx + 1
	}
}

fn (p DartParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut func_name := ''
	mut access := 'public'
	
	// Check for private (starts with _)
	if line.contains('_(') {
		access = 'private'
	}
	
	// Extract function name
	mut re := regex.regex_opt(r'(\w+)\s*\(') or { panic(err) }
	start, _ := re.match_string(line)
	
	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			func_name = line[groups[0].start..groups[0].end]
		}
	}
	
	doc := extract_doc_lines(lines, idx, 2)
	
	// Determine if it's a method based on indentation
	element_type := if lines[idx].starts_with(' ') || lines[idx].starts_with('\t') {
		'method'
	} else {
		'function'
	}
	
	return CodeElement{
		element_type: element_type
		name: func_name
		access: access
		doc: doc
		line_number: idx + 1
	}
}
