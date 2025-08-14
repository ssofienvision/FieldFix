import http from "http";
const PORT = process.env.PORT || 3000;
http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "content-type": "application/json" });
    return res.end(JSON.stringify({ status: "ok", service: "customer-property" }));
  }
  res.writeHead(200, { "content-type": "text/plain" });
  res.end("customer-property service is running\n");
}).listen(PORT, () => console.log("customer-property listening on", PORT));
