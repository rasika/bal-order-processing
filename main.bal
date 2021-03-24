import ballerina/file;
import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;
import ballerina/io;
import ballerina/time;

configurable string watchFilePath = ?;
const string SUCCESS_DIR = "success";
const string FAILED_DIR = "failed";

listener file:Listener inFolder = new ({
    path: watchFilePath,
    recursive: false
});

jdbc:Client dbClient = check new (url = "jdbc:h2:file:./db/accountdb", user = "test", password = "test");

service "localObserver" on inFolder {
    function init() {
        // Create success and fail folders if not exists
        checkpanic file:createDir(checkpanic file:joinPath(watchFilePath, SUCCESS_DIR));
        checkpanic file:createDir(checkpanic file:joinPath(watchFilePath, FAILED_DIR));

        // Create table if not exists
        sql:ExecutionResult|sql:Error execute = dbClient->execute(
        "CREATE TABLE IF NOT EXISTS Orders " + 

        "(id INTEGER, orderTime VARCHAR(255), supplier VARCHAR(255),  customer VARCHAR(255), description VARCHAR(255), qty INTEGER, PRIMARY KEY(id))");
        if (execute is sql:Error) {
            sql:Error e = <sql:Error>execute;
            log:printError("Initializing table failed!");
            panic e;
        }
        log:printInfo("Started listening...");
    }

    remote function onCreate(file:FileEvent event) returns error? {
        log:printDebug(string `Create event received ${event.name}`);
        error? processResult = process(event.name);
        check moveToSubFolder(event.name, processResult is () ? SUCCESS_DIR : FAILED_DIR);
    }
}

type OrderTable table<Order> key(orderId);

type Order record {|
    readonly int orderId;
    string datetime;
    string supplier;
    string customer;
    string description;
    int qty;
|};

function process(string path) returns error? {
    io:ReadableCSVChannel readableCsvFile = check io:openReadableCsvFile(path);
    readableCsvFile.skipHeaders(1);
    transaction {
        sql:ParameterizedQuery[] queries = [];
        while readableCsvFile.hasNext() {
            string[]? row = check readableCsvFile.getNext();
            if row is string[] {
                sql:ParameterizedQuery query = `INSERT INTO Orders (id, orderTime, supplier, 
                customer, description, qty) VALUES (${
                row[0]}, ${row[1]}, ${row[2]}, ${row[3]}, ${row[4]}, ${row[5]})`;
                queries.push(query);
            }
        }

        sql:ExecutionResult[] batchExecute = check dbClient->batchExecute(queries);

        var commitResult = commit;
        if commitResult is () {
            log:printDebug(string `Orders of the file: ${path} successfully committed!`);
        } else {
            log:printDebug(string `Orders of the file: ${path} failed!`);
            panic error("Couldn't added to db");
        }
    }
}

function moveToSubFolder(string path, string subfolder) returns error? {
    string filename = check file:basename(path);
    string newfile = check file:joinPath(watchFilePath, subfolder, filename);
    if check file:test(newfile, file:EXISTS) {
        time:Utc currentUtc = time:utcNow();
        newfile = check file:joinPath(watchFilePath, subfolder, filename + currentUtc[0].toString());
    }
    check file:rename(path, newfile);
}

