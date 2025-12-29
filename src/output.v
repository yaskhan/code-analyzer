module main

import os
import parsers

pub fn write_output(results []parsers.ParseResult, output_path string) ! {
	mut f := os.create(output_path) or {
		return error('Failed to create output file: ${err}')
	}
	defer {
		f.close()
	}

	for result in results {
		if result.elements.len == 0 {
			continue
		}

		// Write file path
		f.write_string('${result.file_path}\n') or {
			return error('Failed to write to output file: ${err}')
		}

		// Write elements
		for element in result.elements {
			line := format_element(element)
			f.write_string('${line}\n') or {
				return error('Failed to write to output file: ${err}')
			}
		}

		// Add blank line between files
		f.write_string('\n') or {
			return error('Failed to write to output file: ${err}')
		}
	}
}

fn format_element(element parsers.CodeElement) string {
	mut parts := []string{}

	// Add element type prefix for modules
	if element.element_type == 'module' {
		parts << 'module ${element.name}'
	} else if element.element_type == 'class' {
		parts << 'class ${element.name}'
	} else {
		// For functions and methods, add access modifier if not empty
		if element.access.len > 0 && element.access != 'public' {
			parts << element.access
		} else if element.access == 'public' {
			parts << 'public'
		}

		// Add element type and name
		parts << '${element.element_type} ${element.name}()'
	}

	// Add inheritance if present
	if element.parent.len > 0 {
		result := parts.join(' ') + ' – inherited ${element.parent}'
		parts = [result]
	}

	// Add documentation if present
	if element.doc.len > 0 {
		return parts.join(' ') + ' – ${element.doc}'
	}

	return parts.join(' ')
}
