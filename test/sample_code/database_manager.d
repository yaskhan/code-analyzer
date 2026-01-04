// Database Query Builder and Executor
// Demonstrates D language classes, templates, ranges, and std lib usage

import std.stdio;
import std.array;
import std.string;
import std.conv;
import std.algorithm;
import std.typecons;
import std.variant;
import std.container;
import std.datetime;

/// Database connection configuration
struct DatabaseConfig
{
    string host;
    ushort port;
    string database;
    string username;
    string password;
    bool ssl;
    int timeout;
    
    /// Validates the configuration
    bool validate() const
    {
        return host.length > 0 && 
               port > 0 && 
               port < 65536 && 
               database.length > 0 && 
               username.length > 0;
    }
    
    /// Creates connection string from config
    string toConnectionString() const
    {
        return format("host=%s;port=%d;db=%s;user=%s;ssl=%s", 
                     host, port, database, username, ssl);
    }
}

/// SQL query types
enum QueryType
{
    Select,
    Insert,
    Update,
    Delete,
    Create,
    Drop,
    Alter
}

/// Query parameter structure
struct QueryParameter
{
    string name;
    Variant value;
    ParameterDirection direction = ParameterDirection.In;
}

/// Parameter direction enum
enum ParameterDirection
{
    In,
    Out,
    InOut
}

/// Base query result interface
interface IQueryResult
{
    bool hasRows() const;
    size_t rowCount() const;
    string[] getColumnNames() const;
    Row getRow(size_t index) const;
    Row[] getAllRows() const;
}

/// Represents a single row of query results
struct Row
{
    private string[] columnNames;
    private Variant[] values;
    
    this(string[] names, Variant[] vals)
    {
        columnNames = names;
        values = vals;
    }
    
    /// Gets value by column index
    T getValue(T)(size_t columnIndex) const
    {
        if (columnIndex >= columnNames.length)
        {
            throw new Exception("Column index out of bounds");
        }
        return values[columnIndex].get!T;
    }
    
    /// Gets value by column name
    T getValue(T)(string columnName) const
    {
        auto index = columnNames.countUntil(columnName);
        if (index == -1)
        {
            throw new Exception("Column not found: " ~ columnName);
        }
        return getValue!T(index);
    }
    
    /// Checks if column exists
    bool hasColumn(string columnName) const
    {
        return columnNames.countUntil(columnName) != -1;
    }
    
    /// Gets column names
    string[] getColumnNames() const
    {
        return columnNames.dup;
    }
}

/// SQL query builder class
class QueryBuilder
{
    private QueryType queryType;
    private string tableName;
    private string[] selectColumns;
    private string[] insertColumns;
    private Variant[] insertValues;
    private string[] updateColumns;
    private Variant[] updateValues;
    private string[] whereConditions;
    private QueryParameter[] parameters;
    private string[] orderByColumns;
    private string[] groupByColumns;
    private string[] havingConditions;
    private size_t limitCount;
    private size_t offsetCount;
    
    this(string table)
    {
        tableName = table;
        queryType = QueryType.Select;
    }
    
    /// Sets query type to SELECT
    QueryBuilder select(string[] columns ...)
    {
        queryType = QueryType.Select;
        selectColumns = columns.dup;
        return this;
    }
    
    /// Sets query type to INSERT
    QueryBuilder insert(string[] columns ...)
    {
        queryType = QueryType.Insert;
        insertColumns = columns.dup;
        insertValues.length = 0;
        return this;
    }
    
    /// Adds INSERT value
    QueryBuilder value(Variant val)
    {
        insertValues ~= val;
        return this;
    }
    
    /// Sets query type to UPDATE
    QueryBuilder update(string[] columns ...)
    {
        queryType = QueryType.Update;
        updateColumns = columns.dup;
        updateValues.length = 0;
        return this;
    }
    
    /// Adds UPDATE value
    QueryBuilder setValue(Variant val)
    {
        updateValues ~= val;
        return this;
    }
    
    /// Sets query type to DELETE
    QueryBuilder delete()
    {
        queryType = QueryType.Delete;
        return this;
    }
    
    /// Adds WHERE condition
    QueryBuilder where(string condition)
    {
        whereConditions ~= condition;
        return this;
    }
    
    /// Adds parameter
    QueryBuilder parameter(string name, Variant value, ParameterDirection direction = ParameterDirection.In)
    {
        parameters ~= QueryParameter(name, value, direction);
        return this;
    }
    
    /// Adds ORDER BY clause
    QueryBuilder orderBy(string column, bool ascending = true)
    {
        orderByColumns ~= ascending ? column : column ~ " DESC";
        return this;
    }
    
    /// Adds GROUP BY clause
    QueryBuilder groupBy(string column)
    {
        groupByColumns ~= column;
        return this;
    }
    
    /// Adds HAVING condition
    QueryBuilder having(string condition)
    {
        havingConditions ~= condition;
        return this;
    }
    
    /// Sets LIMIT clause
    QueryBuilder limit(size_t count)
    {
        limitCount = count;
        return this;
    }
    
    /// Sets OFFSET clause
    QueryBuilder offset(size_t count)
    {
        offsetCount = count;
        return this;
    }
    
    /// Builds the SQL query string
    string build() const
    {
        string query;
        
        final switch (queryType)
        {
            case QueryType.Select:
                query = buildSelectQuery();
                break;
                
            case QueryType.Insert:
                query = buildInsertQuery();
                break;
                
            case QueryType.Update:
                query = buildUpdateQuery();
                break;
                
            case QueryType.Delete:
                query = buildDeleteQuery();
                break;
                
            case QueryType.Create:
            case QueryType.Drop:
            case QueryType.Alter:
                throw new Exception("DDL queries not supported in this builder");
        }
        
        return query;
    }
    
    /// Gets query parameters
    QueryParameter[] getParameters() const
    {
        return parameters.dup;
    }
    
    private string buildSelectQuery() const
    {
        string query = "SELECT ";
        
        if (selectColumns.length == 0)
        {
            query ~= "*";
        }
        else
        {
            query ~= selectColumns.join(", ");
        }
        
        query ~= " FROM " ~ tableName;
        
        if (whereConditions.length > 0)
        {
            query ~= " WHERE " ~ whereConditions.join(" AND ");
        }
        
        if (groupByColumns.length > 0)
        {
            query ~= " GROUP BY " ~ groupByColumns.join(", ");
        }
        
        if (havingConditions.length > 0)
        {
            query ~= " HAVING " ~ havingConditions.join(" AND ");
        }
        
        if (orderByColumns.length > 0)
        {
            query ~= " ORDER BY " ~ orderByColumns.join(", ");
        }
        
        if (limitCount > 0)
        {
            query ~= " LIMIT " ~ limitCount.to!string;
        }
        
        if (offsetCount > 0)
        {
            query ~= " OFFSET " ~ offsetCount.to!string;
        }
        
        return query;
    }
    
    private string buildInsertQuery() const
    {
        string query = "INSERT INTO " ~ tableName ~ " (";
        query ~= insertColumns.join(", ");
        query ~= ") VALUES (";
        
        auto placeholders = iota(insertValues.length)
                            .map!(i => "@param" ~ i.to!string)
                            .array();
        query ~= placeholders.join(", ");
        query ~= ")";
        
        return query;
    }
    
    private string buildUpdateQuery() const
    {
        string query = "UPDATE " ~ tableName ~ " SET ";
        
        auto setClauses = zip(updateColumns, updateValues)
                          .map!(p => p[0] ~ " = @param" ~ updateValues.countUntil(p[1]).to!string)
                          .array();
        query ~= setClauses.join(", ");
        
        if (whereConditions.length > 0)
        {
            query ~= " WHERE " ~ whereConditions.join(" AND ");
        }
        
        return query;
    }
    
    private string buildDeleteQuery() const
    {
        string query = "DELETE FROM " ~ tableName;
        
        if (whereConditions.length > 0)
        {
            query ~= " WHERE " ~ whereConditions.join(" AND ");
        }
        
        return query;
    }
}

/// Database connection and execution manager
class DatabaseConnection
{
    private DatabaseConfig config;
    private bool isConnected;
    private SysTime lastActivity;
    
    this(DatabaseConfig cfg)
    {
        config = cfg;
        isConnected = false;
    }
    
    /// Connects to the database
    bool connect()
    {
        if (!config.validate())
        {
            writeln("Invalid database configuration");
            return false;
        }
        
        // Simulate connection (in real implementation, would use actual DB driver)
        writeln("Connecting to database: ", config.host);
        writeln("Database: ", config.database);
        
        isConnected = true;
        lastActivity = Clock.currTime();
        return true;
    }
    
    /// Disconnects from the database
    void disconnect()
    {
        if (isConnected)
        {
            writeln("Disconnecting from database");
            isConnected = false;
        }
    }
    
    /// Executes a query and returns results
    IQueryResult executeQuery(string sql, QueryParameter[] parameters = [])
    {
        if (!isConnected)
        {
            throw new Exception("Not connected to database");
        }
        
        writeln("Executing SQL: ", sql);
        writeln("Parameters: ", parameters.length);
        
        // Update last activity time
        lastActivity = Clock.currTime();
        
        // Simulate query execution and return mock results
        return new MockQueryResult();
    }
    
    /// Executes a non-query statement (INSERT, UPDATE, DELETE)
    int executeNonQuery(string sql, QueryParameter[] parameters = [])
    {
        if (!isConnected)
        {
            throw new Exception("Not connected to database");
        }
        
        writeln("Executing SQL: ", sql);
        writeln("Parameters: ", parameters.length);
        
        // Update last activity time
        lastActivity = Clock.currTime();
        
        // Simulate affected rows
        return 1;
    }
    
    /// Gets connection status
    bool isConnectedToDatabase() const
    {
        return isConnected;
    }
    
    /// Gets last activity time
    SysTime getLastActivity() const
    {
        return lastActivity;
    }
}

/// Mock query result for demonstration purposes
class MockQueryResult : IQueryResult
{
    private Row[] mockRows;
    
    this()
    {
        // Create mock data
        string[] columns = ["id", "name", "email", "created_at"];
        Variant[][] values = [
            [Variant(1), Variant("John Doe"), Variant("john@example.com"), Variant("2023-01-15")],
            [Variant(2), Variant("Jane Smith"), Variant("jane@example.com"), Variant("2023-02-20")],
            [Variant(3), Variant("Bob Johnson"), Variant("bob@example.com"), Variant("2023-03-10")]
        ];
        
        foreach (rowValues; values)
        {
            mockRows ~= Row(columns.dup, rowValues.dup);
        }
    }
    
    bool hasRows() const
    {
        return mockRows.length > 0;
    }
    
    size_t rowCount() const
    {
        return mockRows.length;
    }
    
    string[] getColumnNames() const
    {
        if (mockRows.length > 0)
        {
            return mockRows[0].getColumnNames();
        }
        return [];
    }
    
    Row getRow(size_t index) const
    {
        if (index >= mockRows.length)
        {
            throw new Exception("Row index out of bounds");
        }
        return mockRows[index];
    }
    
    Row[] getAllRows() const
    {
        return mockRows.dup;
    }
}

/// Database manager utility class
class DatabaseManager
{
    private DatabaseConnection connection;
    
    this(DatabaseConfig config)
    {
        connection = new DatabaseConnection(config);
    }
    
    /// Initializes the database connection
    bool initialize()
    {
        return connection.connect();
    }
    
    /// Executes a simple SELECT query
    Row[] selectAll(string table, string[] columns = ["*"])
    {
        auto query = new QueryBuilder(table)
            .select(columns);
        
        auto result = connection.executeQuery(query.build());
        return result.getAllRows();
    }
    
    /// Executes a SELECT query with conditions
    Row[] selectWhere(string table, string condition, string[] columns = ["*"])
    {
        auto query = new QueryBuilder(table)
            .select(columns)
            .where(condition);
        
        auto result = connection.executeQuery(query.build());
        return result.getAllRows();
    }
    
    /// Inserts a record into a table
    int insert(string table, string[] columns, Variant[] values)
    {
        auto query = new QueryBuilder(table)
            .insert(columns);
        
        foreach (value; values)
        {
            query = query.value(value);
        }
        
        return connection.executeNonQuery(query.build());
    }
    
    /// Updates records in a table
    int update(string table, string[] columns, Variant[] values, string condition)
    {
        auto query = new QueryBuilder(table)
            .update(columns);
        
        foreach (value; values)
        {
            query = query.setValue(value);
        }
        
        return connection.executeNonQuery(query.build());
    }
    
    /// Gets connection status
    bool isConnected() const
    {
        return connection.isConnectedToDatabase();
    }
    
    /// Cleanup resources
    void dispose()
    {
        if (connection !is null)
        {
            connection.disconnect();
        }
    }
}

/// Main function demonstrating the database framework
void main()
{
    try
    {
        writeln("Database Query Builder Framework");
        writeln("================================\n");
        
        // Configure database connection
        auto config = DatabaseConfig(
            "localhost",           // host
            5432,                  // port  
            "myapp_db",            // database
            "admin",               // username
            "password",            // password
            false,                 // ssl
            30                     // timeout
        );
        
        writeln("Database Configuration:");
        writeln("  Host: ", config.host);
        writeln("  Port: ", config.port);
        writeln("  Database: ", config.database);
        writeln("  Valid: ", config.validate());
        writeln();
        
        // Create database manager
        auto dbManager = new DatabaseManager(config);
        
        // Initialize connection
        writeln("Initializing database connection...");
        if (!dbManager.initialize())
        {
            writeln("Failed to initialize database");
            return;
        }
        writeln("Database connected successfully\n");
        
        // Test SELECT query
        writeln("Testing SELECT query...");
        try
        {
            auto rows = dbManager.selectAll("users", ["id", "name", "email"]);
            writeln("Found ", rows.length, " users:");
            
            foreach (i, row; rows)
            {
                writeln("  User ", i + 1, ":");
                writeln("    ID: ", row.getValue!int("id"));
                writeln("    Name: ", row.getValue!string("name"));
                writeln("    Email: ", row.getValue!string("email"));
            }
        }
        catch (Exception ex)
        {
            writeln("SELECT query failed: ", ex.msg);
        }
        writeln();
        
        // Test INSERT query
        writeln("Testing INSERT query...");
        try
        {
            string[] columns = ["name", "email", "created_at"];
            Variant[] values = [Variant("Alice Brown"), Variant("alice@example.com"), Variant("2023-04-01")];
            
            int affectedRows = dbManager.insert("users", columns, values);
            writeln("INSERT affected ", affectedRows, " rows");
        }
        catch (Exception ex)
        {
            writeln("INSERT query failed: ", ex.msg);
        }
        writeln();
        
        // Test parameterized query
        writeln("Testing parameterized query...");
        try
        {
            auto query = new QueryBuilder("users")
                .select("id", "name", "email")
                .where("created_at > @start_date")
                .parameter("start_date", Variant("2023-01-01"))
                .orderBy("created_at", true)
                .limit(10);
            
            writeln("Generated SQL: ", query.build());
            writeln("Parameters: ", query.getParameters().length);
        }
        catch (Exception ex)
        {
            writeln("Parameterized query failed: ", ex.msg);
        }
        
        // Cleanup
        dbManager.dispose();
        writeln("\nDatabase manager disposed");
    }
    catch (Exception ex)
    {
        writeln("Application error: ", ex.msg);
    }
}