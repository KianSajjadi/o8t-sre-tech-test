Problems:
1. **Cold Start Times**: The API can be slow on the first request.
2. **Reliability & Scaling**: Is the current architecture robust enough?
3. **Costs**: As traffic grows, how do we keep costs manageable?


Proposed Solutions:
Cold start
- provisioned concurrency: add warm instances for lambda, this will cost money for each concurrent instance and will need to be adjusted based on minimum usage
- api gateway caching
- redis cache, adds complexity requiring a VPC setup where the lambda and elasticache live in the same VPC
- Memory caching in code? 

Reliability and Scaling


Costs


Monitoring and observability
I've chosen AWS resources to use for this due to convenience's sake, however this can be done with datadog, newrelic, etc.
- Cloudwatch Alarms
  - Lambda Errors: 5 errors in 5 minutes
  - Lambda duration: function taking greater than 5 seconds
  - Lambda throttles: more than 5 per 5 min, this can be further granularised if using lambda managed instances
  - API 5xx errors
  - API Latency

- AWS X-Ray and logging for lambda

