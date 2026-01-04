module main

pub struct ProgressTracker {
pub mut:
	verbose         bool
	files_processed int
	files_failed    int
	total_files     int
}

pub fn (mut p ProgressTracker) init(verbose bool, total int) {
	p.verbose = verbose
	p.total_files = total
	p.files_processed = 0
	p.files_failed = 0
}

pub fn (mut p ProgressTracker) report_file(file_path string) {
	p.files_processed++
	if p.verbose {
		eprintln('Processing [${p.files_processed}/${p.total_files}]: ${file_path}')
	}
}

pub fn (mut p ProgressTracker) report_error(file_path string, err string) {
	p.files_failed++
	eprintln('Error processing ${file_path}: ${err}')
}

pub fn (p ProgressTracker) print_summary() {
	if p.verbose {
		eprintln('\n--- Summary ---')
		eprintln('Total files processed: ${p.files_processed}')
		eprintln('Files with errors: ${p.files_failed}')
		eprintln('Successfully analyzed: ${p.files_processed - p.files_failed}')
	}
}
