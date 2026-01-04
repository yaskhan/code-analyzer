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

		// Remove attributes for parsing
		clean_line := p.strip_attributes(trimmed)

		// Parse const declarations (pub const)
		if p.is_const_declaration(clean_line) {
			result.elements << p.parse_const(lines, i)
		}
		// Parse module definitions
		else if clean_line.starts_with('module ') {
			result.elements << p.parse_module(lines, i)
		}
		// Parse enum definitions
		else if p.is_enum_declaration(clean_line) {
			result.elements << p.parse_enum(lines, i)
		}
		// Parse struct definitions (including pub struct)
		else if p.is_struct_declaration(clean_line) {
			result.elements << p.parse_struct(lines, i)
		}
		// Parse interface definitions (including pub interface)
		else if p.is_interface_declaration(clean_line) {
			result.elements << p.parse_interface(lines, i)
		}
		// Parse function/method definitions (including pub fn)
		else if p.is_function_declaration(clean_line) {
			element := p.parse_function(lines, i)
			if element.name != '' {
				result.elements << element
			}
		}
		// Parse match expressions
		else if p.is_match_expression(clean_line) {
			result.elements << p.parse_match(lines, i)
		}
	}

	return result
}

// Helper functions to identify declarations

fn (p VlangParser) strip_attributes(line string) string {
	mut result := line
	// Remove @[...] attributes
	for result.starts_with('@[') {
		end_idx := result.index(']') or { break }
		result = result[end_idx + 1..].trim_space()
	}
	return result
}

fn (p VlangParser) is_const_declaration(line string) bool {
	return line.starts_with('pub const ') || line.starts_with('const ')
}

fn (p VlangParser) is_enum_declaration(line string) bool {
	return line.starts_with('pub enum ') || line.starts_with('enum ')
}

fn (p VlangParser) is_struct_declaration(line string) bool {
	return line.starts_with('pub struct ') || line.starts_with('struct ')
		|| line.starts_with('pub mut struct ') || line.starts_with('__global struct ')
}

fn (p VlangParser) is_interface_declaration(line string) bool {
	return line.starts_with('pub interface ') || line.starts_with('interface ')
}

fn (p VlangParser) is_function_declaration(line string) bool {
	return line.starts_with('pub fn ') || line.starts_with('pub mut fn ') || line.starts_with('fn ')
		|| line.starts_with('__global fn ')
}

fn (p VlangParser) is_match_expression(line string) bool {
	return line.starts_with('match ')
}

// Parse functions for each declaration type

fn (p VlangParser) parse_module(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()

	mut mod_name := ''

	// Extract module name
	mut re := regex.regex_opt(r'module\s+(\w+)') or { panic(err) }
	start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 && groups[0].end > groups[0].start {
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

fn (p VlangParser) parse_const(lines []string, idx int) CodeElement {
	line := p.strip_attributes(lines[idx].trim_space())

	mut const_name := ''
	mut access := 'private'

	// Determine access level and strip prefix for regex
	mut line_for_regex := line
	if line.starts_with('pub ') {
		access = 'public'
		line_for_regex = line[4..]
	}

	// Extract const name - handle various const patterns:
	// pub const NAME = value
	// pub const (NAME1 = value1, NAME2 = value2)
	mut re := regex.regex_opt(r'const\s+(\w+)') or { panic(err) }
	start, _ := re.match_string(line_for_regex)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 && groups[0].end > groups[0].start {
			const_name = line_for_regex[groups[0].start..groups[0].end]
		}
	}

	doc := extract_doc_lines(lines, idx, 3)

	return CodeElement{
		element_type: 'constant'
		name:         const_name
		access:       access
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p VlangParser) parse_struct(lines []string, idx int) CodeElement {
	line := p.strip_attributes(lines[idx].trim_space())

	mut struct_name := ''
	mut access := 'private'

	// Determine access level and strip prefix for regex
	mut line_for_regex := line
	if line.starts_with('pub mut ') {
		access = 'public'
		line_for_regex = line[8..]
	} else if line.starts_with('pub ') {
		access = 'public'
		line_for_regex = line[4..]
	}

	// Extract struct name - handle:
	// pub struct Name
	// struct Name
	// pub mut struct Name
	mut re := regex.regex_opt(r'struct\s+(\w+)') or { panic(err) }
	start, _ := re.match_string(line_for_regex)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 && groups[0].end > groups[0].start {
			struct_name = line_for_regex[groups[0].start..groups[0].end]
		}
	}

	doc := extract_doc_lines(lines, idx, 5)

	return CodeElement{
		element_type: 'struct'
		name:         struct_name
		access:       access
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p VlangParser) parse_enum(lines []string, idx int) CodeElement {
	line := p.strip_attributes(lines[idx].trim_space())

	mut enum_name := ''
	mut access := 'private'

	// Determine access level and strip prefix for regex
	mut line_for_regex := line
	if line.starts_with('pub ') {
		access = 'public'
		line_for_regex = line[4..]
	}

	// Extract enum name - handle:
	// pub enum Name
	// enum Name
	mut re := regex.regex_opt(r'enum\s+(\w+)') or { panic(err) }
	start, _ := re.match_string(line_for_regex)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 && groups[0].end > groups[0].start {
			enum_name = line_for_regex[groups[0].start..groups[0].end]
		}
	}

	doc := extract_doc_lines(lines, idx, 5)

	return CodeElement{
		element_type: 'enum'
		name:         enum_name
		access:       access
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p VlangParser) parse_interface(lines []string, idx int) CodeElement {
	line := p.strip_attributes(lines[idx].trim_space())

	mut interface_name := ''
	mut parent := ''

	// Determine access level and strip prefix for regex
	mut line_for_regex := line
	mut access := if line.starts_with('pub ') { 'public' } else { 'private' }
	if line.starts_with('pub ') {
		line_for_regex = line[4..]
	}

	// Extract interface name - handle:
	// pub interface Name
	// pub interface Name [implements Interface1, Interface2]
	mut re := regex.regex_opt(r'interface\s+(\w+)') or { panic(err) }
	start, _ := re.match_string(line_for_regex)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 && groups[0].end > groups[0].start {
			interface_name = line_for_regex[groups[0].start..groups[0].end]
		}
	}

	// Check for implements clause separately
	if line.contains('[implements') {
		impl_start := line.index('[implements') or { 0 }
		if impl_start > 0 {
			impl_part := line[impl_start..]
			impl_end := impl_part.index(']') or { impl_part.len }
			if impl_end > 0 {
				parent = impl_part[11..impl_end].trim_space() // Skip "[implements"
			}
		}
	}

	doc := extract_doc_lines(lines, idx, 5)

	return CodeElement{
		element_type: 'interface'
		name:         interface_name
		access:       access
		parent:       parent
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p VlangParser) parse_function(lines []string, idx int) CodeElement {
	line := p.strip_attributes(lines[idx].trim_space())

	mut func_name := ''
	mut access := 'private'

	// Determine access level and strip prefix for regex
	mut line_for_regex := line
	if line.starts_with('pub ') {
		access = 'public'
		line_for_regex = line[4..]
	}

	// Extract function name - handle various VLang patterns:
	// pub fn name()
	// fn name()
	// pub fn (receiver &Type) name()
	// pub fn (mut receiver Type) name()
	mut re := regex.regex_opt(r'fn\s+(?:\([^)]+\)\s+)?(\w+)\s*\(') or { panic(err) }
	start, _ := re.match_string(line_for_regex)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 && groups[0].end > groups[0].start {
			func_name = line_for_regex[groups[0].start..groups[0].end]
		}
	}

	doc := extract_doc_lines(lines, idx, 2)

	// Check if it's a method (has receiver in parentheses)
	// Pattern: fn (receiver Type) or fn (mut receiver Type)
	is_method := line.contains('fn (')

	element_type := if is_method { 'method' } else { 'function' }

	return CodeElement{
		element_type: element_type
		name:         func_name
		access:       access
		doc:          doc
		line_number:  idx + 1
	}
}

fn (p VlangParser) parse_match(lines []string, idx int) CodeElement {
	line := p.strip_attributes(lines[idx].trim_space())

	mut match_var := ''

	// Extract match variable - handle:
	// match variable
	// match expr {
	mut re := regex.regex_opt(r'match\s+(\w+)') or { panic(err) }
	start, _ := re.match_string(line)

	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 && groups[0].start >= 0 && groups[0].end > groups[0].start {
			match_var = line[groups[0].start..groups[0].end]
		}
	}

	doc := extract_doc_lines(lines, idx, 3)

	return CodeElement{
		element_type: 'match_expression'
		name:         match_var
		doc:          doc
		line_number:  idx + 1
	}
}
