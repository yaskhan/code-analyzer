module parsers

import regex

pub struct CParser {}

pub fn (p CParser) get_extensions() []string {
	return ['.c']
}

pub fn (p CParser) parse(content string, file_path string) ParseResult {
	mut result := ParseResult{
		file_path: file_path
		elements:  []CodeElement{}
	}

	lines := content.split_into_lines()

	for i, line in lines {
		trimmed := line.trim_space()

		// Skip comments, preprocessor directives, and forward declarations
		if trimmed.starts_with('//') || trimmed.starts_with('/*') || trimmed.starts_with('#')
			|| trimmed.ends_with(';') {
			continue
		}

		// Parse struct definitions
		if trimmed.starts_with('struct ') || trimmed.starts_with('typedef struct') {
			result.elements << p.parse_struct(lines, i)
		}
		// Parse function definitions (not declarations)
		else if p.is_function_definition(trimmed) {
			element := p.parse_function(lines, i)
			if element.name != '' {
				result.elements << element
			}
		}
	}

	return result
}

fn (p CParser) is_function_definition(line string) bool {
	if line.starts_with('//') || line.starts_with('/*') || line.starts_with('#') {
		return false
	}
	trimmed := line.trim_space()
	if trimmed.starts_with('if') || trimmed.starts_with('while') || trimmed.starts_with('for')
		|| trimmed.starts_with('switch') || trimmed.contains('} else if')
		|| trimmed.starts_with('else if') {
		return false
	}
	// Function definitions usually have opening brace or span multiple lines
	return line.contains('(') && !line.ends_with(';')
}

fn (p CParser) parse_struct(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut struct_name := ''

	// Extract struct name
	mut re := regex.regex_opt(r'(?:typedef\s+)?struct\s+(\w+)') or { panic(err) }
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

fn (p CParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut func_name := ''

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

	return CodeElement{
		element_type: 'function'
		name:         func_name
		access:       'public'
		doc:          doc
		line_number:  idx + 1
	}
}
