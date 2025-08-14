import http from "http";
const PORT = process.env.PORT || 3000;
const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "content-type": "application/json" });
    return res.end(JSON.stringify({ status: "ok", service: "identity-access" }));
  }
  res.writeHead(200, { "content-type": "text/plain" });
  res.end("identity-access service is running\n");
});
server.listen(PORT, () => console.log("identity-access listening on", PORT));
