import http from 'k6/http';

// Ramps up to 100 requests per second, holds, then ramps down.
export const options = {
  scenarios: {
    pico: {
      executor: 'ramping-arrival-rate',
      startRate: 10,
      timeUnit: '1s',
      preAllocatedVUs: 200,
      maxVUs: 1000,
      stages: [
        { target: 100, duration: '1m' },
        { target: 100, duration: '2m' },
        { target: 0, duration: '30s' },
      ],
    },
  },
};

export default function () {
  http.get('http://127.0.0.1:8080/');
}
