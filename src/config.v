module main

import os
import json

pub struct CustomLanguageRule {
pub mut:
	extension          string
	class_pattern      string
	function_pattern   string
	method_pattern     string
	module_pattern     string
	doc_comment_marker string
	doc_before_element bool
}

pub struct Config {
pub mut:
	custom_languages []CustomLanguageRule
}

pub fn load_config(config_path string) !Config {
	if !os.exists(config_path) {
		return error('Config file not found: ${config_path}')
	}

	content := os.read_file(config_path) or { return error('Failed to read config file: ${err}') }

	// Try to parse as JSON
	if config_path.ends_with('.json') {
		config := json.decode(Config, content) or {
			return error('Failed to parse JSON config: ${err}')
		}
		return config
	}

	// For YAML, we'll do basic parsing since V doesn't have built-in YAML support
	if config_path.ends_with('.yaml') || config_path.ends_with('.yml') {
		return parse_yaml_config(content)
	}

	return error('Unsupported config file format. Use .json or .yaml')
}

fn parse_yaml_config(content string) !Config {
	mut config := Config{}
	mut current_lang := CustomLanguageRule{}
	mut in_custom_languages := false

	lines := content.split_into_lines()

	for line in lines {
		trimmed := line.trim_space()

		// Skip comments and empty lines
		if trimmed.starts_with('#') || trimmed.len == 0 {
			continue
		}

		if trimmed.starts_with('custom_languages:') {
			in_custom_languages = true
			continue
		}

		if in_custom_languages {
			if trimmed.starts_with('- extension:') {
				// Save previous language if exists
				if current_lang.extension.len > 0 {
					config.custom_languages << current_lang
				}
				current_lang = CustomLanguageRule{}
				current_lang.extension = extract_yaml_value(trimmed)
			} else if trimmed.contains('class_pattern:') {
				current_lang.class_pattern = extract_yaml_value(trimmed)
			} else if trimmed.contains('function_pattern:') {
				current_lang.function_pattern = extract_yaml_value(trimmed)
			} else if trimmed.contains('method_pattern:') {
				current_lang.method_pattern = extract_yaml_value(trimmed)
			} else if trimmed.contains('module_pattern:') {
				current_lang.module_pattern = extract_yaml_value(trimmed)
			} else if trimmed.contains('doc_comment_marker:') {
				current_lang.doc_comment_marker = extract_yaml_value(trimmed)
			} else if trimmed.contains('doc_before_element:') {
				val := extract_yaml_value(trimmed)
				current_lang.doc_before_element = val == 'true'
			}
		}
	}

	// Save last language
	if current_lang.extension.len > 0 {
		config.custom_languages << current_lang
	}

	return config
}

fn extract_yaml_value(line string) string {
	parts := line.split(':')
	if parts.len < 2 {
		return ''
	}

	value := parts[1..].join(':').trim_space()

	// Remove quotes if present
	if value.starts_with('"') && value.ends_with('"') {
		return value[1..value.len - 1]
	}
	if value.starts_with("'") && value.ends_with("'") {
		return value[1..value.len - 1]
	}

	return value
}
