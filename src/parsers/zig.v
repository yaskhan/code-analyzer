module parsers

import regex

pub struct ZigParser {}

pub fn (p ZigParser) get_extensions() []string {
	return ['.zig']
}

pub fn (p ZigParser) parse(content string, file_path string) ParseResult {
	mut result := ParseResult{
		file_path: file_path
		elements: []CodeElement{}
	}

	lines := content.split_into_lines()
	
	for i, line in lines {
		trimmed := line.trim_space()
		
		// Skip empty lines
		if trimmed.len == 0 {
			continue
		}
		
		// Parse struct definitions
		if trimmed.starts_with('const ') && trimmed.contains('= struct') || 
		   trimmed.starts_with('pub const ') && trimmed.contains('= struct') {
			result.elements << p.parse_struct(lines, i)
		}
		// Parse function definitions
		else if trimmed.starts_with('fn ') || trimmed.starts_with('pub fn ') {
			result.elements << p.parse_function(lines, i)
		}
	}

	return result
}

fn (p ZigParser) parse_struct(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut struct_name := ''
	mut access := ''
	
	// Check for pub modifier
	if line.starts_with('pub const ') {
		access = 'pub'
	}
	
	// Extract struct name
	mut re := regex.regex_opt(r'(?:pub )?const\s+(\w+)\s*=\s*struct') or { panic(err) }
	start, _ := re.match_string(line)
	
	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 {
			struct_name = line[groups[0].start..groups[0].end]
		}
	}
	
	doc := extract_doc_lines(lines, idx, 5)
	
	return CodeElement{
		element_type: 'struct'
		name: struct_name
		access: access
		doc: doc
		line_number: idx + 1
	}
}

fn (p ZigParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut func_name := ''
	mut access := ''
	
	// Check for pub modifier
	if line.starts_with('pub fn ') {
		access = 'pub'
	}
	
	// Extract function name
	mut re := regex.regex_opt(r'(?:pub )?fn\s+(\w+)\s*\(') or { panic(err) }
	start, _ := re.match_string(line)
	
	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 {
			func_name = line[groups[0].start..groups[0].end]
		}
	}
	
	doc := extract_doc_lines(lines, idx, 2)
	
	return CodeElement{
		element_type: 'function'
		name: func_name
		access: access
		doc: doc
		line_number: idx + 1
	}
}
