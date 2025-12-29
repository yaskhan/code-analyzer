/**
 * A processor trait that defines the interface for data processing.
 * All processors must implement the process method.
 */
trait Processor {
  def process(input: String): String
  def getName(): String
}

/**
 * A simple text processor that converts text to uppercase.
 */
class TextProcessor extends Processor {
  /**
   * Processes the input text by converting to uppercase.
   * @param input The text to process
   * @return Processed uppercase text
   */
  def process(input: String): String = {
    input.toUpperCase
  }
  
  def getName(): String = {
    "TextProcessor"
  }
}

/**
 * A data processor that handles numeric data transformations.
 */
class DataProcessor extends Processor {
  private var counter: Int = 0
  
  def process(input: String): String = {
    counter += 1
    s"Processed #$counter: $input"
  }
  
  def getName(): String = {
    "DataProcessor"
  }
  
  protected def reset(): Unit = {
    counter = 0
  }
}

/**
 * Companion object for creating processor instances.
 */
object ProcessorFactory {
  /**
   * Creates a new text processor instance.
   */
  def createTextProcessor(): TextProcessor = {
    new TextProcessor()
  }
  
  def createDataProcessor(): DataProcessor = {
    new DataProcessor()
  }
}

// Utility functions
def formatOutput(result: String): String = {
  s">>> $result"
}

private def log(message: String): Unit = {
  println(s"[LOG] $message")
}
