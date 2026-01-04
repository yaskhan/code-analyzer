module parsers

import regex

pub struct CppParser {}

pub fn (p CppParser) get_extensions() []string {
    return ['.cpp', '.cc', '.cxx', '.hpp', '.h', '.hxx']
}

pub fn (p CppParser) parse(content string, file_path string) ParseResult {
    mut result := ParseResult{
        file_path: file_path
        elements:  []CodeElement{}
    }

    lines := content.split_into_lines()

    for i, line in lines {
        trimmed := line.trim_space()

        // Skip comments and preprocessor directives
        if trimmed.starts_with('//') || trimmed.starts_with('/*') || trimmed.starts_with('#') {
            continue
        }

        // Parse class/struct definitions
        if trimmed.starts_with('class ') || trimmed.starts_with('struct ') {
            result.elements << p.parse_class(lines, i)
        }
        // Parse function/method definitions
        else if p.is_function_line(trimmed) && trimmed.contains('(') && !trimmed.ends_with(';') {
            element := p.parse_function(lines, i)
            if element.name != '' {
                result.elements << element
            }
        }
    }

    return result
}

fn (p CppParser) is_function_line(line string) bool {
    if line.starts_with('//') || line.starts_with('/*') || line.starts_with('#') {
        return false
    }
    trimmed := line.trim_space()
    if trimmed.starts_with('if') || trimmed.starts_with('while') || trimmed.starts_with('for')
        || trimmed.starts_with('switch') || trimmed.contains('} else if')
        || trimmed.starts_with('else if') {
        return false
    }
    return line.contains('(') && (line.contains('{') || line.contains(')'))
}

fn (p CppParser) parse_class(lines []string, idx int) CodeElement {
    line := lines[idx].trim_space()

    mut class_name := ''
    mut parent := ''

    // Find keyword position
    mut start_pos := line.index('class ') or { -1 }
    if start_pos == -1 { start_pos = line.index('struct ') or { -1 } }

    relevant_line := if start_pos != -1 { line[start_pos..] } else { line }

    // Extract class name and inheritance
    mut re := regex.regex_opt(r'\w+\s+([\w:]+)(?:\s*:\s*(?:public|private|protected)?\s*([\w:]+))?') or {
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

fn (p CppParser) parse_function(lines []string, idx int) CodeElement {
    line := lines[idx].trim_space()

    mut func_name := ''
    mut access := 'public'

    // Check for access modifiers in previous lines
    if idx > 0 {
        for j := idx - 1; j >= 0 && j > idx - 5; j-- {
            prev := lines[j].trim_space()
            if prev == 'private:' {
                access = 'private'
                break
            } else if prev == 'protected:' {
                access = 'protected'
                break
            } else if prev == 'public:' {
                access = 'public'
                break
            }
        }
    }

    // Extract function name - take the last word before '('
    before_paren := line.split('(')[0].trim_space()
    if before_paren.len > 0 {
        parts := before_paren.split(' ')
        potential_name := parts[parts.len - 1].trim_space()
        // Remove modifiers like & or * from the name
        mut clean_name := potential_name
        if clean_name.starts_with('*') || clean_name.starts_with('&') {
            clean_name = clean_name[1..]
        }
        if clean_name !in ['if', 'for', 'while', 'switch', 'catch', 'else'] {
            func_name = clean_name
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
