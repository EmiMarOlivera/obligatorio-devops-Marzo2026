import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 5 },
    { duration: '1m', target: 5 },
    { duration: '10s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],       // menos del 5% de requests fallidas
    http_req_duration: ['p(95)<2000'],    // 95% de requests responden en menos de 2s
  },
};

const BASE_URL = __ENV.K6_BASE_URL || 'http://localhost:8080';

export default function () {
  const catalog = http.get(`${BASE_URL}/catalog/products`);
  check(catalog, {
    'catalog products: status 200': (r) => r.status === 200,
    'catalog products: responde en menos de 2s': (r) => r.timings.duration < 2000,
  });

  sleep(1);
}
