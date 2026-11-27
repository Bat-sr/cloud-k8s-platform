// Simple load test for the app. Run it against the Ingress (port 80), not port-forward,
// so the traffic is spread over all pods:
//   k6 run -e BASE_URL=http://<node-public-ip> loadtest/k6-load.js
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "30s", target: 20 },   // warm up
    { duration: "3m", target: 80 },    // push hard enough to trigger the HPA
    { duration: "30s", target: 0 },    // cool down
  ],
  thresholds: {
    http_req_failed: ["rate<0.05"],     // fewer than 5% errors
    http_req_duration: ["p(95)<1000"],  // 95% of requests under 1 second
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:8081";

export default function () {
  const res = http.get(`${BASE_URL}/api/info`);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(0.1);
}
