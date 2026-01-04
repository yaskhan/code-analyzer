# Blog Management System
# Demonstrates Ruby classes, modules, mixins, blocks, and metaprogramming

require 'date'

# Blog post class representing a blog article
class BlogPost
  attr_accessor :title, :content, :author, :published_at, :tags, :id
  attr_reader :created_at, :updated_at
  
  @@next_id = 1
  @@posts = []
  
  # Constructor for BlogPost
  def initialize(title, content, author)
    @id = @@next_id
    @@next_id += 1
    @title = title
    @content = content
    @author = author
    @created_at = Time.now
    @updated_at = Time.now
    @published_at = nil
    @tags = []
    @@posts << self
  end
  
  # Publishes the blog post
  def publish!
    @published_at = Time.now
    @updated_at = Time.now
  end
  
  # Checks if post is published
  def published?
    !@published_at.nil?
  end
  
  # Gets word count of the content
  def word_count
    @content.split(/\s+/).count
  end
  
  # Gets reading time estimate (200 words per minute)
  def reading_time_minutes
    (word_count / 200.0).ceil
  end
  
  # Adds a tag to the post
  def add_tag(tag)
    @tags << tag unless @tags.include?(tag)
  end
  
  # Removes a tag from the post
  def remove_tag(tag)
    @tags.delete(tag)
  end
  
  # Updates the post
  def update(title: nil, content: nil)
    @title = title if title
    @content = content if content
    @updated_at = Time.now
  end
  
  # Gets excerpt (first 150 characters)
  def excerpt(length = 150)
    @content.length > length ? "#{@content[0...length]}..." : @content
  end
  
  # Class methods
  class << self
    # Gets all posts
    def all
      @@posts.dup
    end
    
    # Finds post by ID
    def find(id)
      @@posts.find { |post| post.id == id }
    end
    
    # Finds posts by author
    def find_by_author(author)
      @@posts.select { |post| post.author == author }
    end
    
    # Finds posts by tag
    def find_by_tag(tag)
      @@posts.select { |post| post.tags.include?(tag) }
    end
    
    # Gets published posts
    def published
      @@posts.select(&:published?)
    end
    
    # Gets draft posts
    def drafts
      @@posts.reject(&:published?)
    end
    
    # Searches posts by content
    def search(query)
      @@posts.select { |post| 
        post.title.downcase.include?(query.downcase) ||
        post.content.downcase.include?(query.downcase)
      }
    end
    
    # Gets recent posts
    def recent(limit = 5)
      @@posts.sort_by(&:created_at).reverse[0...limit]
    end
    
    # Clears all posts (for testing)
    def clear_all
      @@posts.clear
      @@next_id = 1
    end
  end
  
  # Instance methods for string representation
  def to_s
    "#{@title} by #{@author}#{" (Published: #{@published_at.strftime('%Y-%m-%d')})" if published?}"
  end
  
  def inspect
    "#<BlogPost id=#{@id} title=\"#{@title}\" author=\"#{@author}\">"
  end
end

# Comment class for blog post comments
class Comment
  attr_accessor :content, :author, :email
  attr_reader :created_at, :id
  
  @@next_id = 1
  @@comments = []
  
  def initialize(content, author, email = nil)
    @id = @@next_id
    @@next_id += 1
    @content = content
    @author = author
    @email = email
    @created_at = Time.now
    @@comments << self
  end
  
  # Class methods for Comment
  class << self
    def all
      @@comments.dup
    end
    
    def find(id)
      @@comments.find { |comment| comment.id == id }
    end
    
    def find_by_author(author)
      @@comments.select { |comment| comment.author == author }
    end
    
    def clear_all
      @@comments.clear
      @@next_id = 1
    end
  end
  
  def to_s
    "#{@author}: #{@content}"
  end
end

# Blog management module
module BlogManager
  # Statistics module for blog analytics
  module Statistics
    def self.total_posts
      BlogPost.all.count
    end
    
    def self.published_posts
      BlogPost.published.count
    end
    
    def self.draft_posts
      BlogPost.drafts.count
    end
    
    def self.total_word_count
      BlogPost.all.sum(&:word_count)
    end
    
    def self.average_word_count
      posts = BlogPost.all
      posts.empty? ? 0 : total_word_count / posts.count
    end
    
    def self.most_prolific_author
      authors = BlogPost.all.map(&:author)
      authors.empty? ? nil : authors.max_by { |author| authors.count(author) }
    end
    
    def self.top_tags(limit = 5)
      all_tags = BlogPost.all.flat_map(&:tags)
      all_tags.group_by(&:itself)
              .transform_values(&:count)
              .sort_by(&:last)
              .reverse
              .take(limit)
              .map(&:first)
    end
    
    def self.posts_by_month
      BlogPost.all.group_by { |post| post.created_at.strftime('%Y-%m') }
              .transform_values(&:count)
    end
  end
  
  # Export functionality
  module Exporter
    def self.to_json
      BlogPost.all.map do |post|
        {
          id: post.id,
          title: post.title,
          content: post.content,
          author: post.author,
          created_at: post.created_at,
          published_at: post.published_at,
          tags: post.tags
        }
      end.to_json
    end
    
    def self.to_csv
      require 'csv'
      
      CSV.generate do |csv|
        csv << ['ID', 'Title', 'Author', 'Created At', 'Published At', 'Tags', 'Word Count']
        BlogPost.all.each do |post|
          csv << [
            post.id,
            post.title,
            post.author,
            post.created_at.strftime('%Y-%m-%d %H:%M'),
            post.published_at&.strftime('%Y-%m-%d %H:%M') || 'Draft',
            post.tags.join(', '),
            post.word_count
          ]
        end
      end
    end
    
    def self.to_html
      html = "<html><head><title>Blog Export</title></head><body>\n"
      html << "<h1>Blog Posts</h1>\n"
      
      BlogPost.all.each do |post|
        html << "<article>\n"
        html << "<h2>#{post.title}</h2>\n"
        html << "<p><strong>Author:</strong> #{post.author}</p>\n"
        html << "<p><strong>Created:</strong> #{post.created_at.strftime('%Y-%m-%d %H:%M')}</p>\n"
        if post.published?
          html << "<p><strong>Published:</strong> #{post.published_at.strftime('%Y-%m-%d %H:%M')}</p>\n"
        end
        html << "<div>#{post.content.gsub(/\n/, '<br>')}</div>\n"
        html << "<p><strong>Tags:</strong> #{post.tags.join(', ')}</p>\n"
        html << "<hr>\n"
        html << "</article>\n"
      end
      
      html << "</body></html>"
    end
  end
  
  # RSS feed generator
  class RSSFeed
    def initialize(title, description, site_url)
      @title = title
      @description = description
      @site_url = site_url
    end
    
    def generate
      rss = RSS::Maker.make("2.0") do |rss|
        rss.channel.title = @title
        rss.channel.description = @description
        rss.channel.link = @site_url
        rss.channel.language = 'en-us'
        
        BlogPost.published.each do |post|
          rss.items.new_item do |item|
            item.title = post.title
            item.description = post.content
            item.pub_date = post.published_at
            item.link = "#{@site_url}/posts/#{post.id}"
          end
        end
      end
      
      rss.to_s
    end
  end
end

# Custom validator module
module Validators
  def self.validate_email(email)
    email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  end
  
  def self.validate_url(url)
    url =~ /\Ahttps?:\/\/[^\s]+\z/i
  end
  
  def self.sanitize_filename(filename)
    filename.gsub(/[^\w\-_\.]/, '_')
  end
end

# Blog configuration class
class BlogConfig
  attr_accessor :title, :description, :author, :email, :site_url, :posts_per_page
  attr_reader :settings
  
  def initialize
    @title = "My Blog"
    @description = "A great blog about everything"
    @author = "Anonymous"
    @email = "admin@example.com"
    @site_url = "https://myblog.com"
    @posts_per_page = 10
    @settings = {}
  end
  
  def update(**kwargs)
    kwargs.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
      @settings[key] = value
    end
  end
  
  def to_h
    {
      title: @title,
      description: @description,
      author: @author,
      email: @email,
      site_url: @site_url,
      posts_per_page: @posts_per_page
    }.merge(@settings)
  end
end

# Blog application class
class BlogApp
  attr_reader :config
  
  def initialize(config = BlogConfig.new)
    @config = config
  end
  
  def create_post(title, content, author)
    BlogPost.new(title, content, author)
  end
  
  def publish_post(post_id)
    post = BlogPost.find(post_id)
    post&.publish!
  end
  
  def add_comment(post_id, content, author, email = nil)
    post = BlogPost.find(post_id)
    Comment.new(content, author, email) if post
  end
  
  def list_posts(limit = 10)
    BlogPost.recent(limit)
  end
  
  def search_posts(query)
    BlogPost.search(query)
  end
  
  def get_statistics
    BlogManager::Statistics
  end
  
  def export_posts(format)
    case format.to_s.downcase
    when 'json'
      BlogManager::Exporter.to_json
    when 'csv'
      BlogManager::Exporter.to_csv
    when 'html'
      BlogManager::Exporter.to_html
    else
      raise ArgumentError, "Unsupported format: #{format}"
    end
  end
  
  def generate_rss
    feed = BlogManager::RSSFeed.new(@config.title, @config.description, @config.site_url)
    feed.generate
  end
  
  # Method that uses blocks for custom processing
  def process_posts(&block)
    BlogPost.all.each do |post|
      block.call(post)
    end
  end
  
  # Method that uses metaprogramming to add dynamic methods
  def self.add_dynamic_methods(*method_names)
    method_names.each do |method_name|
      define_method(method_name) do |*args|
        "Dynamic method #{method_name} called with args: #{args.inspect}"
      end
    end
  end
end

# Add some dynamic methods to BlogApp
BlogApp.add_dynamic_methods(:dynamic_feature, :experimental_method)

# Example usage and testing
if __FILE__ == $PROGRAM_NAME
  puts "Blog Management System Demo"
  puts "=" * 40
  
  # Create blog app
  blog = BlogApp.new
  config = BlogConfig.new
  config.update(title: "Tech Blog", author: "John Doe")
  
  puts "\n1. Creating blog posts..."
  
  # Create some sample posts
  post1 = blog.create_post(
    "Introduction to Ruby Metaprogramming",
    "Ruby is a dynamic language that supports metaprogramming...",
    "John Doe"
  )
  post1.add_tag("ruby")
  post1.add_tag("metaprogramming")
  post1.add_tag("programming")
  
  post2 = blog.create_post(
    "Building RESTful APIs with Rails",
    "Rails provides excellent support for building RESTful APIs...",
    "Jane Smith"
  )
  post2.add_tag("rails")
  post2.add_tag("api")
  post2.add_tag("web development")
  
  post3 = blog.create_post(
    "Blog Post Draft",
    "This is a draft post that hasn't been published yet.",
    "John Doe"
  )
  post3.add_tag("draft")
  
  # Publish some posts
  blog.publish_post(post1.id)
  blog.publish_post(post2.id)
  
  puts "Created #{BlogPost.all.length} posts, published #{BlogPost.published.length}"
  
  # Add comments
  puts "\n2. Adding comments..."
  blog.add_comment(post1.id, "Great post! Very informative.", "Reader123")
  blog.add_comment(post1.id, "Thanks for sharing this.", "DevFan")
  blog.add_comment(post2.id, "This helped me a lot with my project.", "WebDev2023")
  
  puts "Added #{Comment.all.length} comments"
  
  # Display statistics
  puts "\n3. Blog Statistics:"
  stats = blog.get_statistics
  puts "  Total posts: #{stats.total_posts}"
  puts "  Published posts: #{stats.published_posts}"
  puts "  Draft posts: #{stats.draft_posts}"
  puts "  Total word count: #{stats.total_word_count}"
  puts "  Average word count: #{stats.average_word_count}"
  puts "  Most prolific author: #{stats.most_prolific_author}"
  puts "  Top tags: #{stats.top_tags(3).join(', ')}"
  
  # Display recent posts
  puts "\n4. Recent posts:"
  blog.list_posts(3).each do |post|
    puts "  #{post}"
    puts "    Reading time: #{post.reading_time_minutes} minutes"
    puts "    Tags: #{post.tags.join(', ')}"
    puts "    #{post.excerpt(80)}"
    puts
  end
  
  # Search functionality
  puts "5. Searching for 'rails':"
  results = blog.search_posts("rails")
  results.each do |post|
    puts "  Found: #{post.title}"
  end
  
  # Demonstrate block usage
  puts "\n6. Processing posts with custom block:"
  blog.process_posts do |post|
    puts "  #{post.title} (#{post.word_count} words)"
  end
  
  # Demonstrate dynamic methods
  puts "\n7. Dynamic methods:"
  puts "  #{blog.dynamic_feature('test')}"
  puts "  #{blog.experimental_method}"
  
  # Export functionality
  puts "\n8. Export functionality:"
  puts "  JSON export length: #{blog.export_posts('json').length} characters"
  puts "  CSV export lines: #{blog.export_posts('csv').split("\n").length} lines"
  puts "  HTML export length: #{blog.export_posts('html').length} characters"
  
  # Generate RSS feed
  puts "\n9. RSS Feed:"
  rss = blog.generate_rss
  puts "  Generated RSS feed with #{BlogPost.published.length} items"
  puts "  Feed length: #{rss.length} characters"
  
  puts "\nDemo completed successfully!"
end