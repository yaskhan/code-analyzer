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

		// Skip comments
		if trimmed.starts_with('//') || trimmed.starts_with('/*') {
			continue
		}

		// Parse interface definitions
		if trimmed.contains('interface ') {
			element := p.parse_interface(lines, i)
			if element.name != '' {
				result.elements << element
			}
		}
		// Parse class definitions
		else if trimmed.contains('class ') {
			element := p.parse_class(lines, i)
			if element.name != '' {
				result.elements << element
			}
		}
		// Parse function/method definitions
		else if p.is_function_line(trimmed) {
			element := p.parse_function(lines, i)
			if element.name != '' {
				result.elements << element
			}
		}
	}

	return result
}

pub fn (p JsTsParser) is_function_line(line string) bool {
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

	// Check for function patterns, including TypeScript override methods
	// Remove access modifiers and keywords for pattern matching
	mut test_line := line
	if test_line.starts_with('public ') || test_line.starts_with('private ') || test_line.starts_with('protected ') {
		parts := test_line.split(' ')
		if parts.len > 1 {
			test_line = parts[1..].join(' ')
		}
	}
	if test_line.starts_with('override ') {
		test_line = test_line[8..].trim_space()
	}
	if test_line.starts_with('async ') {
		test_line = test_line[6..].trim_space()
	}

	return test_line.contains('function ')
		|| (test_line.contains(') {') && test_line.contains('(') && !test_line.contains('} else if'))
		|| test_line.contains(') =>')
		|| test_line.contains('=>')
		|| (test_line.contains('(') && test_line.ends_with('{') && !test_line.starts_with('if') && !test_line.starts_with('for') && !test_line.starts_with('while') && !test_line.starts_with('switch') && !test_line.starts_with('catch'))
}

fn (p JsTsParser) parse_interface(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut interface_name := ''
	mut parent := ''

	// Extract interface name and inheritance
	mut re := regex.regex_opt(r'export\s+interface\s+(\w+)(?:\s+extends\s+([\w\s,]+))?') or { panic(err) }
	mut start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			interface_name = line[groups[0].start..groups[0].end]
		}
		if groups.len > 1 && groups[1].start >= 0 {
			parent = line[groups[1].start..groups[1].end].trim_space()
		}
	} else {
		// Try without export keyword
		re = regex.regex_opt(r'interface\s+(\w+)(?:\s+extends\s+([\w\s,]+))?') or { panic(err) }
		start, _ = re.match_string(line)
		if start >= 0 {
			groups := re.get_group_list()
			if groups.len > 0 {
				interface_name = line[groups[0].start..groups[0].end]
			}
			if groups.len > 1 && groups[1].start >= 0 {
				parent = line[groups[1].start..groups[1].end].trim_space()
			}
		}
	}

	doc := extract_doc_lines(lines, idx, 5)

	return CodeElement{
		element_type: 'interface'
		name:         interface_name
		parent:       parent
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p JsTsParser) parse_class(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut class_name := ''
	mut parent := ''

	// Extract class name and inheritance - handle export class and regular class
	mut re := regex.regex_opt(r'export\s+class\s+(\w+)(?:\s+extends\s+(\w+))?') or { panic(err) }
	mut start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			class_name = line[groups[0].start..groups[0].end]
		}
		if groups.len > 1 && groups[1].start >= 0 {
			parent = line[groups[1].start..groups[1].end]
		}
	} else {
		// Try without export keyword
		re = regex.regex_opt(r'class\s+(\w+)(?:\s+extends\s+(\w+))?') or { panic(err) }
		start, _ = re.match_string(line)
		if start >= 0 {
			groups := re.get_group_list()
			if groups.len > 0 {
				class_name = line[groups[0].start..groups[0].end]
			}
			if groups.len > 1 && groups[1].start >= 0 {
				parent = line[groups[1].start..groups[1].end]
			}
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
	mut line := lines[idx].trim_space()

	mut func_name := ''
	mut access := 'public'
	mut element_type := 'function'

	// Check for access modifiers and override (TypeScript)
	if line.starts_with('private ') {
		access = 'private'
		line = line[7..].trim_space() // Remove 'private '
	} else if line.starts_with('protected ') {
		access = 'protected'
		line = line[9..].trim_space() // Remove 'protected '
	}

	// Remove 'override' keyword if present
	if line.starts_with('override ') {
		line = line[8..].trim_space() // Remove 'override '
	}

	// Remove 'async' keyword if present
	if line.starts_with('async ') {
		line = line[6..].trim_space() // Remove 'async '
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
	// Methods are typically indented within a class
	if lines[idx].starts_with(' ') || lines[idx].starts_with('\t') {
		element_type = 'method'
	}

	return CodeElement{
		element_type: element_type
		name:         func_name
		access:       access
		doc:          doc
		line_number:  idx + 1
	}
}
