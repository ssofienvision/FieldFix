import http from "http";
const PORT = process.env.PORT || 3000;
http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "content-type": "application/json" });
    return res.end(JSON.stringify({ status: "ok", service: "technicians-dispatch" }));
  }
  res.writeHead(200, { "content-type": "text/plain" });
  res.end("technicians-dispatch service is running\n");
}).listen(PORT, () => console.log("technicians-dispatch listening on", PORT));
