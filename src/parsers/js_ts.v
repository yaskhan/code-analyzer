module parsers

import regex

pub struct JsTsParser {}

pub fn (p JsTsParser) get_extensions() []string {
	return ['.js', '.ts', '.jsx', '.tsx']
}

pub fn (p JsTsParser) parse(content string, file_path string) ParseResult {
	mut result := ParseResult{
		file_path: file_path
		elements:  []CodeElement{}
	}

	lines := content.split_into_lines()

	for i, line in lines {
		trimmed := line.trim_space()

		// Parse class definitions
		if trimmed.contains('class ') && !trimmed.starts_with('//') {
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

fn (p JsTsParser) is_function_line(line string) bool {
	if line.starts_with('//') || line.starts_with('/*') {
		return false
	}

	// Skip control flow statements
	trimmed := line.trim_space()
	if trimmed.starts_with('if') || trimmed.starts_with('for') || trimmed.starts_with('while')
		|| trimmed.starts_with('switch') || trimmed.starts_with('catch')
		|| trimmed.contains('} else if') || trimmed.starts_with('else if') {
		if !trimmed.contains('function ') && !trimmed.contains('=>') {
			return false
		}
	}

	return line.contains('function ') || (line.contains(') {') && line.contains('('))
		|| line.contains(') =>') || line.contains('=>')
}

fn (p JsTsParser) parse_class(lines []string, idx int) CodeElement {
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
		name:         class_name
		parent:       parent
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p JsTsParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut func_name := ''
	mut access := 'public'

	// Check for access modifiers (TypeScript)
	if line.starts_with('private ') {
		access = 'private'
	} else if line.starts_with('protected ') {
		access = 'protected'
	}

	// Try different function patterns
	// Traditional function
	mut re := regex.regex_opt(r'function\s+(\w+)\s*\(') or { panic(err) }
	mut start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			func_name = line[groups[0].start..groups[0].end]
		}
	} else {
		// Method or arrow function pattern: name(...) { or name = (...) =>
		re = regex.regex_opt(r'(\w+)\s*\(') or { panic(err) }
		start, _ = re.match_string(line)
		if start >= 0 {
			groups := re.get_group_list()
			if groups.len > 0 {
				potential_name := line[groups[0].start..groups[0].end]
				if potential_name !in ['if', 'for', 'while', 'switch', 'catch', 'else'] {
					func_name = potential_name
				}
			}
		}
	}

	doc := extract_doc_lines(lines, idx, 2)

	// Determine if it's a method based on indentation or context
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
