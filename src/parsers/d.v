module parsers

import regex

pub struct DParser {}

pub fn (p DParser) get_extensions() []string {
	return ['.d']
}

pub fn (p DParser) parse(content string, file_path string) ParseResult {
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
		// Parse class/struct definitions
		else if trimmed.starts_with('class ') || trimmed.starts_with('struct ') {
			result.elements << p.parse_class(lines, i)
		}
		// Parse function definitions
		else if p.is_function_line(trimmed) {
			element := p.parse_function(lines, i)
			if element.name != '' {
				result.elements << element
			}
		}
	}

	return result
}

fn (p DParser) is_function_line(line string) bool {
	if line.starts_with('//') || line.starts_with('/*') {
		return false
	}
	trimmed := line.trim_space()
	if trimmed.starts_with('if') || trimmed.starts_with('while') || trimmed.starts_with('for')
		|| trimmed.starts_with('switch') || trimmed.contains('} else if')
		|| trimmed.starts_with('else if') {
		return false
	}
	return line.contains('(') && line.contains(')') && (line.contains('void ')
		|| line.contains('int ') || line.contains('auto ')
		|| line.contains('string '))
}

fn (p DParser) parse_module(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut mod_name := ''

	// Extract module name
	mut re := regex.regex_opt(r'module\s+([\w.]+)') or { panic(err) }
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

fn (p DParser) parse_class(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut class_name := ''
	mut parent := ''

	// Extract class name and inheritance
	mut re := regex.regex_opt(r'(?:class|struct)\s+(\w+)(?:\s*:\s*(\w+))?') or { panic(err) }
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

fn (p DParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut func_name := ''
	mut access := 'public'

	// Check for access modifiers
	if line.starts_with('private ') {
		access = 'private'
	} else if line.starts_with('protected ') {
		access = 'protected'
	}

	// Extract function name
	mut re := regex.regex_opt(r'(\w+)\s*\(') or { panic(err) }
	start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			potential_name := line[groups[0].start..groups[0].end]
			if potential_name !in ['if', 'for', 'while', 'switch', 'catch', 'else'] {
				func_name = potential_name
			}
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
