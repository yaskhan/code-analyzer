module parsers

import regex

pub struct GoParser {}

pub fn (p GoParser) get_extensions() []string {
	return ['.go']
}

pub fn (p GoParser) parse(content string, file_path string) ParseResult {
	mut result := ParseResult{
		file_path: file_path
		elements: []CodeElement{}
	}

	lines := content.split_into_lines()
	
	for i, line in lines {
		trimmed := line.trim_space()
		
		// Skip comments
		if trimmed.starts_with('//') || trimmed.starts_with('/*') {
			continue
		}
		
		// Parse type definitions (structs, interfaces)
		if trimmed.starts_with('type ') {
			result.elements << p.parse_type(lines, i)
		}
		// Parse function definitions
		else if trimmed.starts_with('func ') {
			result.elements << p.parse_function(lines, i)
		}
	}

	return result
}

fn (p GoParser) parse_type(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut type_name := ''
	
	// Extract type name
	mut re := regex.regex_opt(r'type\s+(\w+)\s+(?:struct|interface)') or { panic(err) }
	start, _ := re.match_string(line)
	
	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			type_name = line[groups[0].start..groups[0].end]
		}
	}
	
	doc := extract_doc_lines(lines, idx, 5)
	
	return CodeElement{
		element_type: 'class'
		name: type_name
		doc: doc
		line_number: idx + 1
	}
}

fn (p GoParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut func_name := ''
	mut access := 'private'
	
	// Extract function name and check if it's a method
	// Pattern: func (receiver Type) FuncName or func FuncName
	mut re := regex.regex_opt(r'func\s+(?:\([^)]+\)\s+)?(\w+)\s*\(') or { panic(err) }
	start, _ := re.match_string(line)
	
	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			func_name = line[groups[0].start..groups[0].end]
			// In Go, exported names start with uppercase
			if func_name.len > 0 && func_name[0] >= `A` && func_name[0] <= `Z` {
				access = 'public'
			}
		}
	}
	
	doc := extract_doc_lines(lines, idx, 2)
	
	// Check if it's a method (has receiver)
	element_type := if line.contains('func (') {
		'method'
	} else {
		'function'
	}
	
	return CodeElement{
		element_type: element_type
		name: func_name
		access: access
		doc: doc
		line_number: idx + 1
	}
}
