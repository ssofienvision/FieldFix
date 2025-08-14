import http from "http";
const PORT = process.env.PORT || 3000;
const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "content-type": "application/json" });
    return res.end(JSON.stringify({ status: "ok" }));
  }
  res.writeHead(200, { "content-type": "text/plain" });
  res.end("work-management service is running\n");
});
server.listen(PORT, () => console.log(`listening on ${PORT}`));
