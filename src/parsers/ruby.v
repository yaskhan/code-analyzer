module parsers

import regex

pub struct RubyParser {}

pub fn (p RubyParser) get_extensions() []string {
	return ['.rb']
}

pub fn (p RubyParser) parse(content string, file_path string) ParseResult {
	mut result := ParseResult{
		file_path: file_path
		elements: []CodeElement{}
	}

	lines := content.split_into_lines()
	
	for i, line in lines {
		trimmed := line.trim_space()
		
		// Skip comments
		if trimmed.starts_with('#') {
			continue
		}
		
		// Parse module definitions
		if trimmed.starts_with('module ') {
			result.elements << p.parse_module(lines, i)
		}
		// Parse class definitions
		else if trimmed.starts_with('class ') {
			result.elements << p.parse_class(lines, i)
		}
		// Parse method/function definitions
		else if trimmed.starts_with('def ') {
			result.elements << p.parse_function(lines, i)
		}
	}

	return result
}

fn (p RubyParser) parse_module(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut mod_name := ''
	
	// Extract module name
	mut re := regex.regex_opt(r'module\s+(\w+)') or { panic(err) }
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
		name: mod_name
		doc: doc
		line_number: idx + 1
	}
}

fn (p RubyParser) parse_class(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut class_name := ''
	mut parent := ''
	
	// Extract class name and inheritance
	mut re := regex.regex_opt(r'class\s+(\w+)(?:\s*<\s*(\w+))?') or { panic(err) }
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
		name: class_name
		parent: parent
		doc: doc
		line_number: idx + 1
	}
}

fn (p RubyParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut func_name := ''
	mut access := 'public'
	
	// Check previous lines for access modifiers
	if idx > 0 {
		for j := idx - 1; j >= 0 && j > idx - 5; j-- {
			prev := lines[j].trim_space()
			if prev == 'private' {
				access = 'private'
				break
			} else if prev == 'protected' {
				access = 'protected'
				break
			} else if prev == 'public' {
				break
			}
		}
	}
	
	// Extract function name
	mut re := regex.regex_opt(r'def\s+(?:self\.)?(\w+[?!]?)') or { panic(err) }
	start, _ := re.match_string(line)
	
	if start >= 0 {
		groups := re.get_group_list()
		if groups.len > 0 {
			func_name = line[groups[0].start..groups[0].end]
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
		name: func_name
		access: access
		doc: doc
		line_number: idx + 1
	}
}
