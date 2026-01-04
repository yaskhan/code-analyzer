module parsers

import regex

pub struct CSharpParser {}

pub fn (p CSharpParser) get_extensions() []string {
    return ['.cs']
}

pub fn (p CSharpParser) parse(content string, file_path string) ParseResult {
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

        // Parse class/interface/struct definitions
        if trimmed.contains('class ') || trimmed.contains('interface ')
            || trimmed.contains('struct ') {
            result.elements << p.parse_class(lines, i)
        }
        // Parse method definitions
        else if p.is_method_line(trimmed) {
            element := p.parse_method(lines, i)
            if element.name != '' {
                result.elements << element
            }
        }
    }

    return result
}

fn (p CSharpParser) is_method_line(line string) bool {
    if line.starts_with('//') || line.starts_with('/*') {
        return false
    }
    trimmed := line.trim_space()
    if trimmed.starts_with('if') || trimmed.starts_with('while') || trimmed.starts_with('for')
        || trimmed.starts_with('switch') || trimmed.contains('} else if')
        || trimmed.starts_with('else if') {
        return false
    }
    return line.contains('(') && line.contains(')') && (line.contains('void ')
        || line.contains('int ') || line.contains('string ')
        || line.contains('bool ') || line.contains('public ')
        || line.contains('private ') || line.contains('protected ')
        || line.contains('internal '))
}

fn (p CSharpParser) parse_class(lines []string, idx int) CodeElement {
    line := lines[idx].trim_space()

    mut class_name := ''
    mut parent := ''

    // Find the keyword position
    mut start_pos := line.index('class ') or { -1 }
    if start_pos == -1 { start_pos = line.index('interface ') or { -1 } }
    if start_pos == -1 { start_pos = line.index('struct ') or { -1 } }

    relevant_line := if start_pos != -1 { line[start_pos..] } else { line }

    // Extract class name and inheritance
    mut re := regex.regex_opt(r'\w+\s+([\w<> ,]+)(?:\s*:\s*([\w<> ,]+))?') or {
        panic(err)
    }
    start, _ := re.match_string(relevant_line)

    if start >= 0 {
        groups := re.get_group_list()
        if groups.len > 0 {
            class_name = relevant_line[groups[0].start..groups[0].end]
        }
        if groups.len > 1 && groups[1].start >= 0 {
            parent = relevant_line[groups[1].start..groups[1].end]
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

fn (p CSharpParser) parse_method(lines []string, idx int) CodeElement {
    line := lines[idx].trim_space()

    mut method_name := ''
    mut access := 'public'

    // Determine access modifier
    if line.contains('private ') {
        access = 'private'
    } else if line.contains('protected ') {
        access = 'protected'
    } else if line.contains('internal ') {
        access = 'internal'
    }

    // Extract method name - take the last word before '('
    before_paren := line.split('(')[0].trim_space()
    if before_paren.len > 0 {
        parts := before_paren.split(' ')
        potential_name := parts[parts.len - 1].trim_space()
        // Filter out keywords
        if potential_name !in ['if', 'for', 'while', 'switch', 'catch', 'using', 'lock', 'else'] {
            method_name = potential_name
        }
    }

    doc := extract_doc_lines(lines, idx, 2)

    return CodeElement{
        element_type: 'method'
        name:         method_name
        access:       access
        doc:          doc
        line_number:  idx + 1
    }
}
