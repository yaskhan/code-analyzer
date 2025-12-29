module parsers

import regex

pub struct PhpParser {}

pub fn (p PhpParser) get_extensions() []string {
	return ['.php']
}

pub fn (p PhpParser) parse(content string, file_path string) ParseResult {
	mut result := ParseResult{
		file_path: file_path
		elements: []CodeElement{}
	}

	lines := content.split_into_lines()
	
	for i, line in lines {
		trimmed := line.trim_space()
		
		// Skip empty lines and PHP opening/closing tags
		if trimmed.len == 0 || trimmed == '<?php' || trimmed == '?>' || 
		   trimmed.starts_with('<?') {
			continue
		}
		
		// Parse class definitions
		if trimmed.starts_with('class ') || trimmed.starts_with('interface ') || 
		   trimmed.starts_with('trait ') || trimmed.starts_with('abstract class ') {
			result.elements << p.parse_class(lines, i)
		}
		// Parse function/method definitions
		else if trimmed.contains('function ') {
			result.elements << p.parse_function(lines, i)
		}
	}

	return result
}

fn (p PhpParser) parse_class(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut class_name := ''
	mut parent := ''
	mut element_type := 'class'
	
	// Extract class/interface/trait name and inheritance/implementation
	mut re := regex.regex_opt(r'(abstract )?class|interface|trait') or { panic(err) }
	start, _ := re.match_string(line)
	
	if start >= 0 {
		// Determine element type
		if line.starts_with('interface ') {
			element_type = 'interface'
		} else if line.starts_with('trait ') {
			element_type = 'trait'
		} else if line.starts_with('abstract class ') {
			element_type = 'abstract class'
		}
		
		// Extract class name
		mut class_re := regex.regex_opt(r'(?:class|interface|trait)\s+(\w+)') or { panic(err) }
		class_start, _ := class_re.match_string(line)
		if class_start >= 0 {
			class_groups := class_re.get_group_list()
			if class_groups.len > 0 && class_groups[0].start >= 0 {
				class_name = line[class_groups[0].start..class_groups[0].end]
			}
		}
		
		// Extract parent class from extends
		mut extends_re := regex.regex_opt(r'extends\s+(\w+)') or { panic(err) }
		extends_start, _ := extends_re.match_string(line)
		if extends_start >= 0 {
			extends_groups := extends_re.get_group_list()
			if extends_groups.len > 0 && extends_groups[0].start >= 0 {
				parent = line[extends_groups[0].start..extends_groups[0].end]
			}
		}
	}
	
	doc := extract_doc_lines(lines, idx, 5)
	
	return CodeElement{
		element_type: element_type
		name: class_name
		parent: parent
		doc: doc
		line_number: idx + 1
	}
}

fn (p PhpParser) parse_function(lines []string, idx int) CodeElement {
	line := lines[idx].trim_space()
	
	mut func_name := ''
	mut access := 'public'
	
	// Check for access modifiers before 'function'
	if line.starts_with('private function ') {
		access = 'private'
	} else if line.starts_with('protected function ') {
		access = 'protected'
	} else if line.starts_with('public function ') {
		access = 'public'
	} else if line.starts_with('static function ') {
		access = 'static'
	} else if line.starts_with('private static function ') || line.starts_with('static private function ') {
		access = 'private static'
	} else if line.starts_with('protected static function ') || line.starts_with('static protected function ') {
		access = 'protected static'
	} else if line.starts_with('public static function ') || line.starts_with('static public function ') {
		access = 'public static'
	}
	
	// Extract function name
	mut re := regex.regex_opt(r'function\s+(\w+)\s*\(') or { panic(err) }
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
		name: func_name
		access: access
		doc: doc
		line_number: idx + 1
	}
}
