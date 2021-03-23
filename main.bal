import ballerina/file;
import ballerina/log;
// import ballerina/io;

configurable string watch_file_path = ?;
listener file:Listener inFolder = new ({
    path: watch_file_path,
    recursive: false
});

service "localObserver" on inFolder {
    remote function onCreate(file:FileEvent m) {
        string msg = "Create: " + m.name;
        log:printInfo(msg);

        // io:openReadableFile()
    }
}
