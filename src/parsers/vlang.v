module parsers

import regex

pub struct VlangParser {}

pub fn (p VlangParser) get_extensions() []string {
	return ['.v', '.vv']
}

pub fn (p VlangParser) parse(content string, file_path string) ParseResult {
	mut result := ParseResult{
		file_path: file_path
		elements:  []CodeElement{}
	}

	lines := content.split_into_lines()

	for i, line in lines {
		trimmed := line.trim_space()

		// Skip comments
		if trimmed.starts_with('//') || trimmed.starts_with('/*') {
			continue
		}

		// Parse module definitions
		if trimmed.starts_with('module ') {
			result.elements << p.parse_module(lines, i)
		}
		// Parse struct definitions
		else if trimmed.starts_with('struct ') || trimmed.starts_with('pub struct ') {
			result.elements << p.parse_struct(lines, i)
		}
		// Parse interface definitions
		else if trimmed.starts_with('interface ') || trimmed.starts_with('pub interface ') {
			result.elements << p.parse_interface(lines, i)
		}
		// Parse function definitions
		else if trimmed.starts_with('fn ') || trimmed.starts_with('pub fn ') {
			result.elements << p.parse_function(lines, i)
		}
	}

	return result
}

fn (p VlangParser) parse_module(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut mod_name := ''

	// Extract module name
	mut re := regex.regex_opt(r'module\s+(\w+)') or { panic(err) }
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
		name:         mod_name
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p VlangParser) parse_struct(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut struct_name := ''

	// Extract struct name
	mut re := regex.regex_opt(r'struct\s+(\w+)') or { panic(err) }
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
		name:         struct_name
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p VlangParser) parse_interface(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut interface_name := ''

	// Extract interface name
	mut re := regex.regex_opt(r'interface\s+(\w+)') or { panic(err) }
	start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			interface_name = line[groups[0].start..groups[0].end]
		}
	}

	doc := extract_doc_lines(lines, idx, 5)

	return CodeElement{
		element_type: 'class'
		name:         interface_name
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p VlangParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut func_name := ''
	mut access := 'private'

	// Check if it's public
	if line.starts_with('pub fn ') {
		access = 'public'
	}

	// Extract function name - handle both functions and methods
	mut re := regex.regex_opt(r'fn\s+(?:\([^)]+\)\s+)?(\w+)\s*[<(]') or { panic(err) }
	start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			func_name = line[groups[0].start..groups[0].end]
		}
	}

	doc := extract_doc_lines(lines, idx, 2)

	// Check if it's a method (has receiver)
	element_type := if line.contains('fn (') {
		'method'
	} else {
		'function'
	}

	return CodeElement{
		element_type: element_type
		name:         func_name
		access:       access
		doc:          doc
		line_number:  idx + 1
	}
}
