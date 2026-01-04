// Document Processing System
// Demonstrates Rust structs, enums, traits, and methods

/// Document types supported by the system
#[derive(Debug, Clone, PartialEq)]
pub enum DocumentType {
    Text,
    Markdown,
    Html,
    Pdf,
    Word,
}

/// Document processing status
#[derive(Debug, Clone)]
pub enum ProcessingStatus {
    Pending,
    Processing,
    Completed,
    Failed(String),
}

/// Base document structure
#[derive(Debug, Clone)]
pub struct Document {
    pub id: String,
    pub title: String,
    pub content: String,
    pub doc_type: DocumentType,
    pub created_at: std::time::SystemTime,
    pub metadata: DocumentMetadata,
}

/// Document metadata information
#[derive(Debug, Clone)]
pub struct DocumentMetadata {
    pub author: String,
    pub word_count: usize,
    pub language: String,
    pub tags: Vec<String>,
}

impl Document {
    /// Creates a new document
    /// # Arguments
    /// * `id` - Unique document identifier
    /// * `title` - Document title
    /// * `content` - Document content
    /// * `doc_type` - Type of document
    /// * `author` - Document author
    /// # Returns
    /// New Document instance
    pub fn new(id: String, title: String, content: String, doc_type: DocumentType, author: String) -> Self {
        let word_count = content.split_whitespace().count();
        let metadata = DocumentMetadata {
            author,
            word_count,
            language: "en".to_string(), // Default language
            tags: Vec::new(),
        };

        Document {
            id,
            title,
            content,
            doc_type,
            created_at: std::time::SystemTime::now(),
            metadata,
        }
    }

    /// Adds a tag to the document
    /// # Arguments
    /// * `tag` - Tag to add
    pub fn add_tag(&mut self, tag: String) {
        if !self.metadata.tags.contains(&tag) {
            self.metadata.tags.push(tag);
        }
    }

    /// Removes a tag from the document
    /// # Arguments
    /// * `tag` - Tag to remove
    /// # Returns
    /// true if tag was found and removed
    pub fn remove_tag(&mut self, tag: &str) -> bool {
        if let Some(index) = self.metadata.tags.iter().position(|t| t == tag) {
            self.metadata.tags.remove(index);
            true
        } else {
            false
        }
    }

    /// Gets document summary (first 100 characters)
    /// # Returns
    /// Summary string
    pub fn get_summary(&self) -> &str {
        if self.content.len() <= 100 {
            &self.content
        } else {
            &self.content[..100]
        }
    }

    /// Updates word count based on content
    pub fn update_word_count(&mut self) {
        self.metadata.word_count = self.content.split_whitespace().count();
    }

    /// Checks if document matches search term
    /// # Arguments
    /// * `search_term` - Term to search for
    /// # Returns
    /// true if term found in title or content
    pub fn contains(&self, search_term: &str) -> bool {
        self.title.to_lowercase().contains(&search_term.to_lowercase())
            || self.content.to_lowercase().contains(&search_term.to_lowercase())
    }
}

/// Document processor trait
pub trait DocumentProcessor {
    /// Processes the document
    /// # Arguments
    /// * `document` - Document to process
    /// # Returns
    /// Processing result with status
    fn process(&self, document: &Document) -> Result<ProcessingStatus, String>;
    
    /// Gets processor name
    /// # Returns
    /// Processor name
    fn name(&self) -> &str;
}

/// Text document processor
pub struct TextProcessor;

impl DocumentProcessor for TextProcessor {
    fn process(&self, document: &Document) -> Result<ProcessingStatus, String> {
        println!("Processing text document: {}", document.title);
        
        if document.content.is_empty() {
            return Err("Document content is empty".to_string());
        }
        
        // Simulate processing time
        std::thread::sleep(std::time::Duration::from_millis(100));
        
        Ok(ProcessingStatus::Completed)
    }
    
    fn name(&self) -> &str {
        "TextProcessor"
    }
}

/// HTML document processor with validation
pub struct HtmlProcessor;

impl DocumentProcessor for HtmlProcessor {
    fn process(&self, document: &Document) -> Result<ProcessingStatus, String> {
        println!("Processing HTML document: {}", document.title);
        
        if !document.content.contains("<html>") && !document.content.contains("<!DOCTYPE") {
            return Err("Invalid HTML structure".to_string());
        }
        
        // Simulate processing time
        std::thread::sleep(std::time::Duration::from_millis(200));
        
        Ok(ProcessingStatus::Completed)
    }
    
    fn name(&self) -> &str {
        "HtmlProcessor"
    }
}

/// Document manager for handling multiple documents
pub struct DocumentManager {
    documents: Vec<Document>,
    processors: Vec<Box<dyn DocumentProcessor>>,
}

impl DocumentManager {
    /// Creates a new document manager
    pub fn new() -> Self {
        DocumentManager {
            documents: Vec::new(),
            processors: Vec::new(),
        }
    }

    /// Adds a document processor
    /// # Arguments
    /// * `processor` - Processor to add
    pub fn add_processor(&mut self, processor: Box<dyn DocumentProcessor>) {
        self.processors.push(processor);
    }

    /// Adds a document to the manager
    /// # Arguments
    /// * `document` - Document to add
    pub fn add_document(&mut self, document: Document) {
        self.documents.push(document);
    }

    /// Finds documents by author
    /// # Arguments
    /// * `author` - Author name to search for
    /// # Returns
    /// Vector of matching documents
    pub fn find_by_author(&self, author: &str) -> Vec<&Document> {
        self.documents
            .iter()
            .filter(|doc| doc.metadata.author.to_lowercase() == author.to_lowercase())
            .collect()
    }

    /// Finds documents by type
    /// # Arguments
    /// * `doc_type` - Document type to search for
    /// # Returns
    /// Vector of matching documents
    pub fn find_by_type(&self, doc_type: &DocumentType) -> Vec<&Document> {
        self.documents
            .iter()
            .filter(|doc| &doc.doc_type == doc_type)
            .collect()
    }

    /// Processes all documents using available processors
    /// # Returns
    /// Vector of processing results
    pub fn process_all_documents(&self) -> Vec<Result<ProcessingStatus, String>> {
        let mut results = Vec::new();
        
        for document in &self.documents {
            for processor in &self.processors {
                let result = processor.process(document);
                results.push(result);
            }
        }
        
        results
    }

    /// Gets total number of documents
    /// # Returns
    /// Document count
    pub fn document_count(&self) -> usize {
        self.documents.len()
    }

    /// Gets documents with specific tag
    /// # Arguments
    /// * `tag` - Tag to search for
    /// # Returns
    /// Vector of documents with the tag
    pub fn find_by_tag(&self, tag: &str) -> Vec<&Document> {
        self.documents
            .iter()
            .filter(|doc| doc.metadata.tags.contains(&tag.to_string()))
            .collect()
    }
}

impl Default for DocumentManager {
    fn default() -> Self {
        Self::new()
    }
}