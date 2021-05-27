const http = require('http');
const os = require('os');

console.log("kubia server starting...");

let handler = function(request, response) {
    console.log("Received request from " + request.connection.remoteAddress);
    response.writeHead(200);
    response.end("You've hit " + os.hostname() + "\n");
};

let www = http.createServer(handler);
www.listen(8080);
