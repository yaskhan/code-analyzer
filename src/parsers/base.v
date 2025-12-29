module parsers

pub struct CodeElement {
pub mut:
	element_type string // 'class', 'function', 'method', 'module'
	name         string
	access       string // 'public', 'private', 'protected', ''
	parent       string // for inheritance
	doc          string // documentation
	line_number  int
}

pub struct ParseResult {
pub mut:
	file_path string
	elements  []CodeElement
}

pub interface Parser {
	parse(content string, file_path string) ParseResult
	get_extensions() []string
}

pub fn extract_doc_lines(lines []string, start_idx int, max_lines int) string {
	mut doc_lines := []string{}
	mut idx := start_idx - 1

	for idx >= 0 && doc_lines.len < max_lines {
		line := lines[idx].trim_space()
		if line.len == 0 {
			idx--
			continue
		}
		if !is_comment_line(line) {
			break
		}
		cleaned := clean_comment(line)
		if cleaned.len > 0 {
			doc_lines.insert(0, cleaned)
		}
		idx--
	}

	return doc_lines.join(' ')
}

fn is_comment_line(line string) bool {
	trimmed := line.trim_space()
	return trimmed.starts_with('//') || trimmed.starts_with('#') || 
	       trimmed.starts_with('/*') || trimmed.starts_with('*') ||
	       trimmed.starts_with('---') || trimmed.starts_with('"""') ||
	       trimmed.starts_with("'''")
}

fn clean_comment(line string) string {
	mut cleaned := line.trim_space()
	
	// Remove common comment markers
	if cleaned.starts_with('///') {
		cleaned = cleaned[3..].trim_space()
	} else if cleaned.starts_with('//') {
		cleaned = cleaned[2..].trim_space()
	} else if cleaned.starts_with('#') {
		cleaned = cleaned[1..].trim_space()
	} else if cleaned.starts_with('/*') {
		cleaned = cleaned[2..].trim_space()
	} else if cleaned.starts_with('*/') {
		cleaned = cleaned[2..].trim_space()
	} else if cleaned.starts_with('*') {
		cleaned = cleaned[1..].trim_space()
	} else if cleaned.starts_with('---') {
		cleaned = cleaned[3..].trim_space()
	} else if cleaned.starts_with('"""') {
		cleaned = cleaned[3..].trim_space()
	} else if cleaned.starts_with("'''") {
		cleaned = cleaned[3..].trim_space()
	}
	
	// Remove trailing comment markers
	if cleaned.ends_with('*/') {
		cleaned = cleaned[..cleaned.len - 2].trim_space()
	} else if cleaned.ends_with('"""') {
		cleaned = cleaned[..cleaned.len - 3].trim_space()
	} else if cleaned.ends_with("'''") {
		cleaned = cleaned[..cleaned.len - 3].trim_space()
	}
	
	return cleaned
}
