module parsers

import regex

pub struct GoParser {}

pub fn (p GoParser) get_extensions() []string {
    return ['.go']
}

pub fn (p GoParser) parse(content string, file_path string) ParseResult {
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

        // Parse type definitions (structs, interfaces)
        if trimmed.starts_with('type ') {
            result.elements << p.parse_type(lines, i)
        }
        // Parse function definitions
        else if trimmed.starts_with('func ') {
            element := p.parse_function(lines, i)
            if element.name != '' {
                result.elements << element
            }
        }
    }

    return result
}

fn (p GoParser) parse_type(lines []string, idx int) CodeElement {
    line := lines[idx].trim_space()

    mut type_name := ''

    // Extract type name
    mut re := regex.regex_opt(r'type\s+(\w+)') or { panic(err) }
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
        name:         type_name
        doc:          doc
        line_number:  idx + 1
    }
}

fn (p GoParser) parse_function(lines []string, idx int) CodeElement {
    line := lines[idx].trim_space()

    mut func_name := ''
    mut access := 'private'

    // Extract function name and check if it's a method
    // Pattern: func (receiver Type) FuncName or func FuncName
    if line.contains('(') {
        before_paren := line.split('(')
        if line.contains('func (') && before_paren.len > 2 {
            // Method with receiver: func (r Receiver) MethodName(
            method_part := before_paren[2].trim_space()
            func_name = method_part.split(' ')[0].split(')')[0].trim_space()
        } else {
            // Ordinary function: func FuncName(
            func_part := before_paren[1].trim_space()
            func_name = func_part.split(' ')[0].trim_space()
            if func_name == '' && before_paren.len > 1 {
                // Handle case like: func(r *Receiver) MethodName()
                // though Go usually has space after func
            }
        }
    }

    if func_name != '' {
        // In Go, exported names start with uppercase
        if func_name.len > 0 && func_name[0] >= `A` && func_name[0] <= `Z` {
            access = 'public'
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
        name:         func_name
        access:       access
        doc:          doc
        line_number:  idx + 1
    }
}
