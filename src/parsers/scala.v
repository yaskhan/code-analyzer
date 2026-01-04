module parsers

import regex

pub struct ScalaParser {}

pub fn (p ScalaParser) get_extensions() []string {
	return ['.scala']
}

pub fn (p ScalaParser) parse(content string, file_path string) ParseResult {
	mut result := ParseResult{
		file_path: file_path
		elements:  []CodeElement{}
	}

	lines := content.split_into_lines()

	for i, line in lines {
		trimmed := line.trim_space()

		// Skip empty lines
		if trimmed.len == 0 {
			continue
		}

		// Parse class, object, trait definitions
		if trimmed.starts_with('class ') || trimmed.starts_with('object ')
			|| trimmed.starts_with('trait ') {
			result.elements << p.parse_class(lines, i)
		}
		// Parse function/method definitions
		else if trimmed.starts_with('def ') {
			result.elements << p.parse_function(lines, i)
		}
	}

	return result
}

fn (p ScalaParser) parse_class(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut class_name := ''
	mut parent := ''
	mut element_type := 'class'

	// Extract class/object/trait name and inheritance
	mut re := regex.regex_opt(r'(class|object|trait)\s+(\w+)(?:\s*\(\s*\))?(?:\s+extends\s+(\w+))?') or {
		panic(err)
	}
	start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 {
			element_type = line[groups[0].start..groups[0].end]
		}
		if groups.len > 1 && groups[1].start >= 0 {
			class_name = line[groups[1].start..groups[1].end]
		}
		if groups.len > 2 && groups[2].start >= 0 {
			parent = line[groups[2].start..groups[2].end]
		}
	}

	doc := extract_doc_lines(lines, idx, 5)

	return CodeElement{
		element_type: element_type
		name:         class_name
		parent:       parent
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p ScalaParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut func_name := ''
	mut access := 'public'

	// Check for access modifiers before 'def'
	if line.starts_with('private def ') {
		access = 'private'
	} else if line.starts_with('protected def ') {
		access = 'protected'
	}

	// Extract function name (including any type parameters)
	mut re := regex.regex_opt(r'def\s+(\w+)\s*\(') or { panic(err) }
	start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 {
			func_name = line[groups[0].start..groups[0].end]
		}
	}

	doc := extract_doc_lines(lines, idx, 2)

	// Determine if it's a method or function based on indentation
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
