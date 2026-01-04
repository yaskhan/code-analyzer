module parsers

import regex

pub struct SwiftParser {}

pub fn (p SwiftParser) get_extensions() []string {
	return ['.swift']
}

pub fn (p SwiftParser) parse(content string, file_path string) ParseResult {
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

		// Parse class/struct/protocol definitions
		if trimmed.contains('class ') || trimmed.contains('struct ')
			|| trimmed.contains('protocol ') || trimmed.contains('enum ') {
			result.elements << p.parse_class(lines, i)
		}
		// Parse function definitions
		else if trimmed.contains('func ') {
			result.elements << p.parse_function(lines, i)
		}
	}

	return result
}

fn (p SwiftParser) parse_class(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut class_name := ''
	mut parent := ''

	// Extract class name and inheritance
	mut re := regex.regex_opt(r'(?:class|struct|protocol|enum)\s+(\w+)(?:\s*:\s*(\w+))?') or {
		panic(err)
	}
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
		name:         class_name
		parent:       parent
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p SwiftParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut func_name := ''
	mut access := 'internal'

	// Check for access modifiers
	if line.starts_with('private ') {
		access = 'private'
	} else if line.starts_with('public ') {
		access = 'public'
	} else if line.starts_with('fileprivate ') {
		access = 'fileprivate'
	} else if line.starts_with('open ') {
		access = 'open'
	}

	// Extract function name
	mut re := regex.regex_opt(r'func\s+(\w+)\s*[<(]') or { panic(err) }
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
		name:         func_name
		access:       access
		doc:          doc
		line_number:  idx + 1
	}
}
