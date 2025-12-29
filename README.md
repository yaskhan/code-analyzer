# Code Analyzer

A powerful console application written in V (Vlang) that recursively analyzes source code directories across multiple programming languages, extracting code structure (modules, classes, methods, functions) and documentation.

## Features

- **Multi-language Support**: Built-in support for 20 programming languages
- **Recursive Analysis**: Scans directories and subdirectories automatically
- **Documentation Extraction**: Captures comments and docstrings before code elements
- **Extensible**: Add custom language support via configuration files
- **Fast Performance**: Efficiently handles projects with thousands of files
- **Cross-platform**: Works on Windows, Linux, and macOS

## Supported Languages

| Language      | Extensions                                      |
|---------------|-------------------------------------------------|
| Java          | `.java`                                         |
| JavaScript    | `.js`, `.jsx`                                   |
| TypeScript    | `.ts`, `.tsx`                                   |
| Dart          | `.dart`                                         |
| Rust          | `.rs`                                           |
| C++           | `.cpp`, `.cc`, `.cxx`, `.hpp`, `.h`, `.hxx`     |
| Python        | `.py`                                           |
| C#            | `.cs`                                           |
| V (Vlang)     | `.v`, `.vv`                                     |
| C             | `.c`                                            |
| D             | `.d`                                            |
| Lua           | `.lua`                                          |
| Pascal        | `.pas`, `.pp`, `.inc`                           |
| Swift         | `.swift`                                        |
| Ruby          | `.rb`                                           |
| Go            | `.go`                                           |
| Kotlin        | `.kt`, `.kts`                                   |
| Scala         | `.scala`                                        |
| PHP           | `.php`                                          |
| Zig           | `.zig`                                          |

## Installation

### Prerequisites

- V (Vlang) compiler installed on your system
- Download from: https://vlang.io

### Build from Source

```bash
# Clone the repository
git clone <repository-url>
cd code-analyzer

# Build the project
v -prod src/main.v -o code-analyzer

# Or simply run without building
v run src/main.v -- --help
```

## Usage

### Basic Usage

```bash
# Analyze a directory
code-analyzer --input ./my-project

# Analyze with verbose output
code-analyzer --input ./my-project --verbose

# Specify output file
code-analyzer --input ./my-project --output analysis.txt
```

### Command Line Options

```
-i, --input <path>      Root directory path (required)
-l, --lang <language>   Programming language filter (optional)
-o, --output <file>     Output file path (default: ./output.txt)
-c, --config <file>     Custom config file path (YAML or JSON)
-v, --verbose           Show progress and details
-h, --help              Show help message
```

### Examples

```bash
# Analyze a Python project
code-analyzer --input ./django-app --lang python --output results.txt

# Analyze all supported languages with progress
code-analyzer --input ./polyglot-project --verbose

# Use custom configuration for additional languages
code-analyzer --input ./src --config ./custom-config.yaml --verbose

# Analyze a specific directory structure
code-analyzer -i /path/to/source -o /path/to/output.txt -v

# Analyze Kotlin files
code-analyzer --input ./kotlin-app --output kotlin-analysis.txt

# Analyze Scala project
code-analyzer --input ./scala-project --verbose

# Analyze PHP application
code-analyzer --input ./wordpress-plugin --output php-output.txt

# Analyze Zig project
code-analyzer --input ./zig-program --verbose
```

## Output Format

The analyzer generates a text file with the following format:

```
path/to/file.extension
class ClassName [– inherited ParentClass] – brief documentation
public method methodName() – method documentation
function functionName() – function documentation
module ModuleName – module documentation

path/to/another/file.extension
...
```

### Example Output

```
src/animals/dog.py
class Dog – inherited Animal – Represents a domestic dog
public method bark() – Emits a loud sound
function feed(pet) – Provides food to the animal

src/utils/helper.js
class StringHelper – Utility class for string operations
public method capitalize() – Capitalizes first letter
function formatDate(date) – Formats a date to string

src/app/Calculator.kt
class Calculator – A simple calculator class
public method add(a Double, b Double) – Adds two numbers together
private method logOperation(op String) – Logs operation
data class Result – Calculation result with timestamp

src/core/Processor.scala
trait Processor – Interface for data processing
class TextProcessor – inherited Processor – Text processor
public method process(input String) – Processes input
object Factory – Factory for creating instances

src/model/User.php
class User – User class representing a user
public method __construct(name, email) – Constructor
private method validateEmail(email) – Validates email
interface UserRepository – Interface for user repos

src/utils/math.zig
pub const struct Point – 2D coordinate point
pub fn add(a f64, b f64) – Adds two numbers
fn square(x f64) – Calculates square of number
```

## Documentation Extraction Rules

- **Classes**: First 5 lines of documentation before the class definition
- **Methods/Functions**: First 2 lines of documentation before the definition
- **Modules**: First 5 lines of documentation before the module declaration
- Comments are automatically cleaned of markers (`//`, `#`, `/*`, `*/`, etc.)
- Empty lines and extra whitespace are removed

## Custom Language Configuration

You can extend the analyzer to support additional languages using a YAML or JSON configuration file.

### YAML Configuration Example

```yaml
custom_languages:
  - extension: ".mylang"
    rules:
      class_pattern: "class\\s+(\\w+)(?:\\s+extends\\s+(\\w+))?"
      function_pattern: "fn\\s+(\\w+)\\s*\\("
      method_pattern: "(public|private)?\\s+method\\s+(\\w+)\\s*\\("
      module_pattern: "module\\s+(\\w+)"
      doc_comment_marker: "#"
      doc_before_element: true
```

### JSON Configuration Example

```json
{
  "custom_languages": [
    {
      "extension": ".mylang",
      "class_pattern": "class\\s+(\\w+)(?:\\s+extends\\s+(\\w+))?",
      "function_pattern": "fn\\s+(\\w+)\\s*\\(",
      "method_pattern": "(public|private)?\\s+method\\s+(\\w+)\\s*\\(",
      "module_pattern": "module\\s+(\\w+)",
      "doc_comment_marker": "#",
      "doc_before_element": true
    }
  ]
}
```

### Using Custom Configuration

```bash
code-analyzer --input ./src --config ./my-config.yaml
```

## Project Structure

```
code-analyzer/
├── v.mod                   # V module configuration
├── README.md               # This file
├── LICENSE                 # License file
├── src/
│   ├── main.v             # Entry point and CLI parsing
│   ├── analyzer.v         # Main analysis logic
│   ├── config.v           # Configuration loading
│   ├── output.v           # Output formatting
│   ├── progress.v         # Progress tracking
│   └── parsers/
│       ├── base.v         # Base parser interface
│       ├── python.v       # Python parser
│       ├── js_ts.v        # JavaScript/TypeScript parser
│       ├── java.v         # Java parser
│       ├── rust.v         # Rust parser
│       ├── cpp.v          # C++ parser
│       ├── csharp.v       # C# parser
│       ├── dart.v         # Dart parser
│       ├── c.v            # C parser
│       ├── d.v            # D parser
│       ├── lua.v          # Lua parser
│       ├── pascal.v       # Pascal parser
│       ├── swift.v        # Swift parser
│       ├── ruby.v         # Ruby parser
│       ├── go.v           # Go parser
│       ├── vlang.v        # V (Vlang) parser
│       ├── kotlin.v       # Kotlin parser
│       ├── scala.v        # Scala parser
│       ├── php.v          # PHP parser
│       └── zig.v          # Zig parser
└── examples/
    ├── config.yaml        # Example configuration
    └── sample_output.txt  # Sample output format
```

## Performance

- Handles up to 10,000 files in ≤ 2 minutes on typical hardware
- Efficient regex-based parsing for fast analysis
- Lazy file reading to minimize memory usage
- Concurrent processing capabilities (future enhancement)

## Error Handling

The analyzer is designed to be robust:

- Gracefully skips unreadable files
- Continues processing after encountering syntax errors
- Logs errors to stderr without crashing
- Reports summary of failed files with `--verbose` flag

## Limitations

- Basic parsing using regex patterns (not full AST analysis)
- May miss complex nested structures
- Documentation extraction limited to comments before definitions
- Custom language support requires regex knowledge
- Does not analyze code semantics or relationships

## Development

### Running Tests

```bash
v test .
```

### Building for Production

```bash
v -prod src/main.v -o code-analyzer
```

### Code Style

- All code follows V language conventions
- English comments only
- Public functions are documented
- Error handling using V's `?` and `!` operators

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Adding a New Language Parser

1. Create a new file in `src/parsers/` (e.g., `kotlin.v`)
2. Implement the `Parser` interface
3. Add the parser to `analyzer.v` in `register_parsers()`
4. Add tests for the new parser
5. Update the README with the new language

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [V (Vlang)](https://vlang.io)
- Inspired by various code analysis tools
- Thanks to all contributors

## Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Check existing documentation
- Review example configurations

## Changelog

### Version 1.1.0
- Added support for Kotlin (.kt, .kts)
- Added support for Scala (.scala)
- Added support for PHP (.php)
- Added support for Zig (.zig)
- Total support for 20 programming languages

### Version 1.0.0
- Initial release
- Support for 16 programming languages
- Basic documentation extraction
- Custom configuration support
- Verbose progress tracking
- Cross-platform compatibility
