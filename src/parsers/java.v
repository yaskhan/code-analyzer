module parsers

import regex

pub struct JavaParser {}

pub fn (p JavaParser) get_extensions() []string {
	return ['.java']
}

pub fn (p JavaParser) parse(content string, file_path string) ParseResult {
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

		// Parse class/interface definitions
		if trimmed.contains('class ') || trimmed.contains('interface ') || trimmed.contains('enum ') {
			if !trimmed.ends_with(';') { // Skip forward declarations
				result.elements << p.parse_class(lines, i)
			}
		}
		// Parse method definitions
		else if p.is_method_line(trimmed) {
			element := p.parse_method(lines, i)
			if element.name != '' {
				result.elements << element
			}
		}
	}

	return result
}

fn (p JavaParser) is_method_line(line string) bool {
	if line.starts_with('//') || line.starts_with('/*') || line.starts_with('*') {
		return false
	}
	trimmed := line.trim_space()
	if trimmed.starts_with('if') || trimmed.starts_with('while') || trimmed.starts_with('for')
		|| trimmed.starts_with('switch') || trimmed.contains('} else if')
		|| trimmed.starts_with('else if') {
		return false
	}
	// Look for method signature pattern
	return line.contains('(') && line.contains(')') && (line.contains('void ')
		|| line.contains('int ') || line.contains('String ')
		|| line.contains('boolean ') || line.contains('public ')
		|| line.contains('private ') || line.contains('protected '))
}

fn (p JavaParser) parse_class(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut class_name := ''
	mut parent := ''

	// Extract class name and inheritance
	mut re := regex.regex_opt(r'(?:class|interface|enum)\s+(\w+)(?:\s+extends\s+(\w+))?') or {
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

fn (p JavaParser) parse_method(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut method_name := ''
	mut access := 'public'

	// Determine access modifier
	if line.contains('private ') {
		access = 'private'
	} else if line.contains('protected ') {
		access = 'protected'
	}

	// Extract method name
	mut re := regex.regex_opt(r'(\w+)\s*\(') or { panic(err) }
	start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			potential_name := line[groups[0].start..groups[0].end]
			// Filter out keywords and types
			if potential_name !in ['if', 'for', 'while', 'switch', 'catch', 'synchronized', 'else'] {
				method_name = potential_name
			}
		}
	}

	doc := extract_doc_lines(lines, idx, 2)

	return CodeElement{
		element_type: 'method'
		name:         method_name
		access:       access
		doc:          doc
		line_number:  idx + 1
	}
}
