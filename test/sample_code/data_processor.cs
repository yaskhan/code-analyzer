// Data Processing Framework
// Demonstrates C# classes, interfaces, async/await, LINQ, and generics

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.IO;

namespace DataProcessingFramework
{
    /// <summary>
    /// Represents the status of a data processing operation
    /// </summary>
    public enum ProcessingStatus
    {
        Pending,
        Running,
        Completed,
        Failed,
        Cancelled
    }

    /// <summary>
    /// Base interface for data processors
    /// </summary>
    /// <typeparam name="TInput">Type of input data</typeparam>
    /// <typeparam name="TOutput">Type of output data</typeparam>
    public interface IDataProcessor<TInput, TOutput>
    {
        /// <summary>
        /// Processes the input data asynchronously
        /// </summary>
        /// <param name="data">Input data to process</param>
        /// <returns>Processing result containing output data and status</returns>
        Task<ProcessingResult<TOutput>> ProcessAsync(TInput data);

        /// <summary>
        /// Gets the processor name
        /// </summary>
        string Name { get; }

        /// <summary>
        /// Gets the processor description
        /// </summary>
        string Description { get; }
    }

    /// <summary>
    /// Represents the result of a data processing operation
    /// </summary>
    /// <typeparam name="T">Type of data in the result</typeparam>
    public class ProcessingResult<T>
    {
        /// <summary>
        /// Gets or sets the processing status
        /// </summary>
        public ProcessingStatus Status { get; set; }

        /// <summary>
        /// Gets or sets the processed data
        /// </summary>
        public T? Data { get; set; }

        /// <summary>
        /// Gets or sets error message if processing failed
        /// </summary>
        public string? ErrorMessage { get; set; }

        /// <summary>
        /// Gets or sets processing timestamp
        /// </summary>
        public DateTime Timestamp { get; set; }

        /// <summary>
        /// Gets or sets processing duration
        /// </summary>
        public TimeSpan? Duration { get; set; }

        /// <summary>
        /// Creates a successful processing result
        /// </summary>
        /// <param name="data">Processed data</param>
        /// <param name="duration">Processing duration</param>
        /// <returns>Successful result</returns>
        public static ProcessingResult<T> Success(T data, TimeSpan? duration = null)
        {
            return new ProcessingResult<T>
            {
                Status = ProcessingStatus.Completed,
                Data = data,
                Timestamp = DateTime.UtcNow,
                Duration = duration
            };
        }

        /// <summary>
        /// Creates a failed processing result
        /// </summary>
        /// <param name="errorMessage">Error message</param>
        /// <returns>Failed result</returns>
        public static ProcessingResult<T> Failure(string errorMessage)
        {
            return new ProcessingResult<T>
            {
                Status = ProcessingStatus.Failed,
                ErrorMessage = errorMessage,
                Timestamp = DateTime.UtcNow
            };
        }
    }

    /// <summary>
    /// Represents a data record with metadata
    /// </summary>
    public class DataRecord
    {
        /// <summary>
        /// Gets or sets the record identifier
        /// </summary>
        public string Id { get; set; } = string.Empty;

        /// <summary>
        /// Gets or sets the record content
        /// </summary>
        public string Content { get; set; } = string.Empty;

        /// <summary>
        /// Gets or sets the record category
        /// </summary>
        public string Category { get; set; } = string.Empty;

        /// <summary>
        /// Gets or sets the record timestamp
        /// </summary>
        public DateTime CreatedAt { get; set; }

        /// <summary>
        /// Gets or sets the record size in bytes
        /// </summary>
        public int Size { get; set; }

        /// <summary>
        /// Gets or sets custom metadata
        /// </summary>
        public Dictionary<string, object> Metadata { get; set; } = new();
    }

    /// <summary>
    /// Text data processor that transforms and analyzes text content
    /// </summary>
    public class TextDataProcessor : IDataProcessor<string, ProcessedTextData>
    {
        private readonly int _maxLength;

        /// <summary>
        /// Gets the processor name
        /// </summary>
        public string Name => "TextDataProcessor";

        /// <summary>
        /// Gets the processor description
        /// </summary>
        public string Description => "Processes and analyzes text data";

        /// <summary>
        /// Initializes a new TextDataProcessor instance
        /// </summary>
        /// <param name="maxLength">Maximum text length to process</param>
        public TextDataProcessor(int maxLength = 10000)
        {
            _maxLength = maxLength;
        }

        /// <summary>
        /// Processes text data asynchronously
        /// </summary>
        /// <param name="data">Text data to process</param>
        /// <returns>Processing result with processed text data</returns>
        public async Task<ProcessingResult<ProcessedTextData>> ProcessAsync(string data)
        {
            var startTime = DateTime.UtcNow;

            try
            {
                if (string.IsNullOrWhiteSpace(data))
                {
                    return ProcessingResult<ProcessedTextData>.Failure("Input data is empty");
                }

                if (data.Length > _maxLength)
                {
                    return ProcessingResult<ProcessedTextData>.Failure($"Text length {data.Length} exceeds maximum {_maxLength}");
                }

                // Simulate async processing
                await Task.Delay(100);

                var processedData = new ProcessedTextData
                {
                    OriginalText = data,
                    WordCount = CountWords(data),
                    CharacterCount = data.Length,
                    LineCount = CountLines(data),
                    AverageWordLength = CalculateAverageWordLength(data),
                    ProcessedAt = DateTime.UtcNow
                };

                var duration = DateTime.UtcNow - startTime;
                return ProcessingResult<ProcessedTextData>.Success(processedData, duration);
            }
            catch (Exception ex)
            {
                return ProcessingResult<ProcessedTextData>.Failure($"Processing failed: {ex.Message}");
            }
        }

        private static int CountWords(string text)
        {
            return text.Split(new[] { ' ', '\t', '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries).Length;
        }

        private static int CountLines(string text)
        {
            return text.Split('\n').Length;
        }

        private static double CalculateAverageWordLength(string text)
        {
            var words = text.Split(new[] { ' ', '\t', '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries);
            return words.Length > 0 ? words.Average(w => w.Length) : 0;
        }
    }

    /// <summary>
    /// Represents processed text data with analysis results
    /// </summary>
    public class ProcessedTextData
    {
        /// <summary>
        /// Gets or sets the original text
        /// </summary>
        public string OriginalText { get; set; } = string.Empty;

        /// <summary>
        /// Gets or sets the word count
        /// </summary>
        public int WordCount { get; set; }

        /// <summary>
        /// Gets or sets the character count
        /// </summary>
        public int CharacterCount { get; set; }

        /// <summary>
        /// Gets or sets the line count
        /// </summary>
        public int LineCount { get; set; }

        /// <summary>
        /// Gets or sets the average word length
        /// </summary>
        public double AverageWordLength { get; set; }

        /// <summary>
        /// Gets or sets when the text was processed
        /// </summary>
        public DateTime ProcessedAt { get; set; }
    }

    /// <summary>
    /// Data processing pipeline that chains multiple processors
    /// </summary>
    /// <typeparam name="TInput">Input data type</typeparam>
    /// <typeparam name="TOutput">Output data type</typeparam>
    public class ProcessingPipeline<TInput, TOutput>
    {
        private readonly List<IDataProcessor<object, object>> _processors = new();

        /// <summary>
        /// Adds a processor to the pipeline
        /// </summary>
        /// <typeparam name="TProcessorInput">Input type for the processor</typeparam>
        /// <typeparam name="TProcessorOutput">Output type for the processor</typeparam>
        /// <param name="processor">Processor to add</param>
        /// <returns>The pipeline for method chaining</returns>
        public ProcessingPipeline<TInput, TOutput> AddProcessor<TProcessorInput, TProcessorOutput>(
            IDataProcessor<TProcessorInput, TProcessorOutput> processor)
        {
            _processors.Add(processor as IDataProcessor<object, object> ?? throw new ArgumentException("Invalid processor type"));
            return this;
        }

        /// <summary>
        /// Executes the processing pipeline asynchronously
        /// </summary>
        /// <param name="input">Input data</param>
        /// <returns>Final processing result</returns>
        public async Task<ProcessingResult<TOutput>> ExecuteAsync(TInput input)
        {
            object? currentData = input;

            foreach (var processor in _processors)
            {
                var result = await processor.ProcessAsync(currentData);
                if (result.Status != ProcessingStatus.Completed)
                {
                    return ProcessingResult<TOutput>.Failure(result.ErrorMessage ?? "Processing failed");
                }
                currentData = result.Data;
            }

            return ProcessingResult<TOutput>.Success((TOutput)currentData!);
        }
    }

    /// <summary>
    /// Data processor factory for creating processors
    /// </summary>
    public static class ProcessorFactory
    {
        /// <summary>
        /// Creates a text data processor
        /// </summary>
        /// <param name="maxLength">Maximum text length</param>
        /// <returns>Text data processor instance</returns>
        public static IDataProcessor<string, ProcessedTextData> CreateTextProcessor(int maxLength = 10000)
        {
            return new TextDataProcessor(maxLength);
        }

        /// <summary>
        /// Creates a data record processor
        /// </summary>
        /// <returns>Data record processor instance</returns>
        public static IDataProcessor<DataRecord, ProcessedTextData> CreateRecordProcessor()
        {
            return new RecordProcessor();
        }
    }

    /// <summary>
    /// Processor for DataRecord objects
    /// </summary>
    public class RecordProcessor : IDataProcessor<DataRecord, ProcessedTextData>
    {
        public string Name => "RecordProcessor";
        public string Description => "Processes DataRecord objects";

        public async Task<ProcessingResult<ProcessedTextData>> ProcessAsync(DataRecord data)
        {
            await Task.Delay(50);

            return ProcessingResult<ProcessedTextData>.Success(new ProcessedTextData
            {
                OriginalText = data.Content,
                WordCount = data.Content.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length,
                CharacterCount = data.Content.Length,
                LineCount = data.Content.Split('\n').Length,
                AverageWordLength = CalculateAverageWordLength(data.Content),
                ProcessedAt = DateTime.UtcNow
            });
        }

        private static double CalculateAverageWordLength(string text)
        {
            var words = text.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            return words.Length > 0 ? words.Average(w => w.Length) : 0;
        }
    }

    /// <summary>
    /// Main application class
    /// </summary>
    public class Program
    {
        /// <summary>
        /// Main entry point
        /// </summary>
        /// <param name="args">Command line arguments</param>
        /// <returns>Application exit code</returns>
        public static async Task<int> Main(string[] args)
        {
            try
            {
                Console.WriteLine("Data Processing Framework");
                Console.WriteLine("=========================");

                // Create and configure processors
                var textProcessor = ProcessorFactory.CreateTextProcessor();
                var recordProcessor = ProcessorFactory.CreateRecordProcessor();

                // Create processing pipeline
                var pipeline = new ProcessingPipeline<string, ProcessedTextData>();
                pipeline.AddProcessor(textProcessor);

                // Process sample text
                string sampleText = @"This is a sample text for processing.
It contains multiple lines and words.
The framework should analyze this content and provide statistics.";

                Console.WriteLine("Processing sample text...");
                var result = await pipeline.ExecuteAsync(sampleText);

                if (result.Status == ProcessingStatus.Completed)
                {
                    var data = result.Data!;
                    Console.WriteLine($"Word Count: {data.WordCount}");
                    Console.WriteLine($"Character Count: {data.CharacterCount}");
                    Console.WriteLine($"Line Count: {data.LineCount}");
                    Console.WriteLine($"Average Word Length: {data.AverageWordLength:F2}");
                    Console.WriteLine($"Processed At: {data.ProcessedAt}");
                }
                else
                {
                    Console.WriteLine($"Processing failed: {result.ErrorMessage}");
                }

                return 0;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Application error: {ex.Message}");
                return 1;
            }
        }
    }
}