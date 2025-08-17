#!/usr/bin/env bash
set -euo pipefail

check() { 
  curl -fsS "$1" >/dev/null && echo "✅ OK $1" || { echo "❌ FAIL $1"; exit 1; }; 
}

check_post() {
  local url="$1"
  local data="$2"
  curl -fsS -X POST -H "Content-Type: application/json" -d "$data" "$url" >/dev/null && echo "✅ OK POST $url" || { echo "❌ FAIL POST $url"; exit 1; }
}

echo "🔍 Testing FieldFix Microservices Health..."

# Direct service health checks
check http://localhost:3000/health
check http://localhost:3001/health
check http://localhost:8080/health

# API Gateway info endpoint
check http://localhost:8080/info

# Test API Gateway route mapping with actual POST endpoints
echo "🔍 Testing API Gateway Route Mapping..."

# Test work order creation via API Gateway
check_post http://localhost:8080/work/orders '{
  "title": "Fix heating system",
  "customerId": "cust-123",
  "address": "123 Main St",
  "priority": "high"
}'

# Test authentication via API Gateway
check_post http://localhost:8080/auth/login '{
  "email": "tech@example.com",
  "password": "Password123!"
}'

echo "🎉 All health checks passed!"
echo "✅ Direct Services: work-management (3000), identity-access (3001)"
echo "✅ API Gateway: routing and health (8080)"
echo "✅ Route Mapping: POST /work/orders → work-management"
echo "✅ Authentication: POST /auth/login → identity-access"
echo ""
echo "🚀 FieldFix microservices stack is running successfully!"
echo ""
echo "📋 Demo credentials: tech@example.com / Password123!"
echo "🔧 Test commands:"
echo "  curl -s localhost:8080/work/orders -X POST -H 'Content-Type: application/json' -d '{\"title\":\"Test\",\"customerId\":\"c1\",\"address\":\"123 St\"}' | jq"
echo "  curl -s localhost:8080/auth/login -X POST -H 'Content-Type: application/json' -d '{\"email\":\"tech@example.com\",\"password\":\"Password123!\"}' | jq"
