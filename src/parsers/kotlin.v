module parsers

import regex

pub struct KotlinParser {}

pub fn (p KotlinParser) get_extensions() []string {
	return ['.kt', '.kts']
}

pub fn (p KotlinParser) parse(content string, file_path string) ParseResult {
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

		// Parse class definitions
		if trimmed.starts_with('class ') || trimmed.starts_with('data class ')
			|| trimmed.starts_with('object ') || trimmed.starts_with('interface ') {
			result.elements << p.parse_class(lines, i)
		}
		// Parse function/method definitions
		else if trimmed.starts_with('fun ') {
			element := p.parse_function(lines, i)
			if element.name != '' {
				result.elements << element
			}
		}
	}

	return result
}

fn (p KotlinParser) parse_class(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut class_name := ''
	mut parent := ''
	mut element_type := 'class'

	// Extract class name and inheritance
	mut re := regex.regex_opt(r'(?:class|data class|interface|object)\s+(\w+)(?:\s*:\s*([\w\s,]+))?') or {
		panic(err)
	}
	start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 {
			class_name = line[groups[0].start..groups[0].end]

			// Determine element type
			if line.starts_with('data class ') {
				element_type = 'data class'
			} else if line.starts_with('interface ') {
				element_type = 'interface'
			} else if line.starts_with('object ') {
				element_type = 'object'
			}
		}
		if groups.len > 1 && groups[1].start >= 0 {
			parent = line[groups[1].start..groups[1].end].split(',')[0].trim_space()
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

fn (p KotlinParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut func_name := ''
	mut access := 'public'

	// Check for access modifiers before 'fun'
	if line.starts_with('private fun ') {
		access = 'private'
	} else if line.starts_with('protected fun ') {
		access = 'protected'
	} else if line.starts_with('internal fun ') {
		access = 'internal'
	}

	// Extract function name
	mut re := regex.regex_opt(r'fun\s+(\w+)\s*\(') or { panic(err) }
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
