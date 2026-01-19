module parsers

import regex

pub struct RustParser {}

pub fn (p RustParser) get_extensions() []string {
	return ['.rs']
}

pub fn (p RustParser) parse(content string, file_path string) ParseResult {
	mut result := ParseResult{
		file_path: file_path
		elements:  []CodeElement{}
	}

	lines := content.split_into_lines()
	mut in_impl_block := false

	for i, line in lines {
		trimmed := line.trim_space()

		// Skip comments and empty lines
		if trimmed.starts_with('//') || trimmed.starts_with('/*') || trimmed == '' {
			continue
		}

		// Check for impl block
		if trimmed.contains('impl ') && trimmed.contains('{') {
			in_impl_block = true
			continue
		}
		
		// Very basic end of block detection
		if trimmed == '}' {
			in_impl_block = false
			continue
		}

		// Parse module definitions
		if (trimmed.starts_with('mod ') || trimmed.contains(' mod ')) && !trimmed.contains('use ') {
			element := p.parse_module(lines, i)
			if element.name != '' {
				result.elements << element
			}
		}
		// Parse struct/enum definitions
		else if (trimmed.contains('struct ') || trimmed.contains('enum ')) && !trimmed.contains('impl ') {
			element := p.parse_struct(lines, i)
			if element.name != '' {
				result.elements << element
			}
		}
		// Parse function/method definitions
		else if trimmed.contains('fn ') {
			element := p.parse_function(lines, i, in_impl_block)
			if element.name != '' {
				result.elements << element
			}
		}
	}

	return result
}

fn (p RustParser) parse_module(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	mut mod_name := ''

	// Find the start of the module declaration
	if pos := line.index('mod ') {
		content := line[pos..]
		mut re := regex.regex_opt(r'mod\s+(\w+)') or { panic(err) }
		start, _ := re.match_string(content)
		if start >= 0 {
			mod_name = re.get_group_by_id(content, 0)
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

fn (p RustParser) parse_struct(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut name := ''
	mut element_type := 'struct'

	if line.contains('enum ') {
		element_type = 'enum'
	}

	// Extract name - find keyword first
	keyword := if element_type == 'enum' { 'enum ' } else { 'struct ' }
	if pos := line.index(keyword) {
		content := line[pos..]
		mut re := if element_type == 'enum' {
			regex.regex_opt(r'enum\s+(\w+)') or { panic(err) }
		} else {
			regex.regex_opt(r'struct\s+(\w+)') or { panic(err) }
		}
		
		start, _ := re.match_string(content)
		if start >= 0 {
			name = re.get_group_by_id(content, 0)
		}
	}

	doc := extract_doc_lines(lines, idx, 5)

	return CodeElement{
		element_type: element_type
		name:         name
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p RustParser) parse_function(lines []string, idx int, in_impl bool) CodeElement {
	line := lines[idx].trim_space()

	mut func_name := ''
	mut access := 'private'

	// Determine access
	if line.contains('pub ') || line.contains('pub(') {
		access = 'public'
	}

	// Extract function name
	if pos := line.index('fn ') {
		content := line[pos..]
		mut re := regex.regex_opt(r'fn\s+(\w+)') or { panic(err) }
		start, _ := re.match_string(content)
		if start >= 0 {
			func_name = re.get_group_by_id(content, 0)
		}
	}

	doc := extract_doc_lines(lines, idx, 2)

	// Determine if it's a method
	element_type := if in_impl {
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
