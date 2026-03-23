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


Monitoring
- Cloudwatch alarms
  - Lambda Errors
  - Lambda duration
  - Lambda throttles
  - API 5xx errors
  - API Latency