module parsers

import regex

pub struct PascalParser {}

pub fn (p PascalParser) get_extensions() []string {
    return ['.pas', '.pp', '.inc']
}

pub fn (p PascalParser) parse(content string, file_path string) ParseResult {
    mut result := ParseResult{
        file_path: file_path
        elements:  []CodeElement{}
    }

    lines := content.split_into_lines()

    for i, line in lines {
        trimmed := line.trim_space()
        lower := trimmed.to_lower()

        // Skip comments
        if trimmed.starts_with('//') || trimmed.starts_with('{') || trimmed.starts_with('(*') {
            continue
        }

        // Parse class definitions
        if lower.starts_with('type') {
            // Look ahead for class definitions
            for j := i + 1; j < lines.len && j < i + 10; j++ {
                line_lower := lines[j].trim_space().to_lower()
                if line_lower.contains('= class') {
                    result.elements << p.parse_class(lines, j)
                }
            }
        }
        // Parse function/procedure definitions
        else if lower.starts_with('function ') || lower.starts_with('procedure ') {
            result.elements << p.parse_function(lines, i)
        }
    }

    return result
}

fn (p PascalParser) parse_class(lines []string, idx int) CodeElement {
    line := lines[idx].trim_space()

    mut class_name := ''
    mut parent := ''

    // Extract class name and inheritance
    mut re := regex.regex_opt(r'(\w+)\s*=\s*class\s*\((\w+)\)?') or { panic(err) }
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
        // Try without inheritance
        re = regex.regex_opt(r'(\w+)\s*=\s*class') or { panic(err) }
        start, _ = re.match_string(line)
        if start >= 0 {
            groups := re.get_group_list()
            if groups.len > 0 {
                class_name = line[groups[0].start..groups[0].end]
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

fn (p PascalParser) parse_function(lines []string, idx int) CodeElement {
    line := lines[idx].trim_space()
    lower := line.to_lower()

    mut func_name := ''
    mut access := 'public'

    // Check for private/protected
    if idx > 0 {
        for j := idx - 1; j >= 0 && j > idx - 5; j-- {
            prev_lower := lines[j].trim_space().to_lower()
            if prev_lower == 'private' {
                access = 'private'
                break
            } else if prev_lower == 'protected' {
                access = 'protected'
                break
            } else if prev_lower == 'public' {
                break
            }
        }
    }

    // Extract function/procedure name
    mut re := regex.regex_opt(r'\w+\s+(\w+)') or { panic(err) }
    start, _ := re.match_string(lower)

    if start >= 0 {
        groups := re.get_group_list()
        if groups.len > 0 {
            func_name = lower[groups[0].start..groups[0].end]
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
        name:         func_name
        access:       access
        doc:          doc
        line_number:  idx + 1
    }
}
