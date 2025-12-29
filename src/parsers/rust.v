module parsers

import regex

pub struct RustParser {}

pub fn (p RustParser) get_extensions() []string {
	return ['.rs']
}

pub fn (p RustParser) parse(content string, file_path string) ParseResult {
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
		
		// Parse module definitions
		if trimmed.starts_with('mod ') {
			result.elements << p.parse_module(lines, i)
		}
		// Parse struct/enum definitions
		else if trimmed.starts_with('struct ') || trimmed.starts_with('enum ') {
			result.elements << p.parse_struct(lines, i)
		}
		// Parse impl blocks (for methods)
		else if trimmed.starts_with('impl ') {
			// We'll handle methods inside impl blocks
			continue
		}
		// Parse function definitions
		else if trimmed.starts_with('fn ') || trimmed.starts_with('pub fn ') || 
		        trimmed.starts_with('pub(crate) fn ') {
			result.elements << p.parse_function(lines, i)
		}
	}

	return result
}

fn (p RustParser) parse_module(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut mod_name := ''
	
	// Extract module name
	mut re := regex.regex_opt(r'mod\s+(\w+)') or { panic(err) }
	start, _ := re.match_string(line)
	
	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			mod_name = line[groups[0].start..groups[0].end]
		}
	}
	
	doc := extract_doc_lines(lines, idx, 5)
	
	return CodeElement{
		element_type: 'module'
		name: mod_name
		doc: doc
		line_number: idx + 1
	}
}

fn (p RustParser) parse_struct(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut struct_name := ''
	
	// Extract struct/enum name
	mut re := regex.regex_opt(r'(?:struct|enum)\s+(\w+)') or { panic(err) }
	start, _ := re.match_string(line)
	
	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			struct_name = line[groups[0].start..groups[0].end]
		}
	}
	
	doc := extract_doc_lines(lines, idx, 5)
	
	return CodeElement{
		element_type: 'class'
		name: struct_name
		doc: doc
		line_number: idx + 1
	}
}

fn (p RustParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut func_name := ''
	mut access := 'private'
	
	// Determine access
	if line.starts_with('pub ') {
		access = 'public'
	}
	
	// Extract function name
	mut re := regex.regex_opt(r'fn\s+(\w+)\s*[<(]') or { panic(err) }
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
