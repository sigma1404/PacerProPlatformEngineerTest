# PacerProDevOpsTest
PacerPro DevOps Test Solution files and approach


# Assumptions

Log format:

{
responseTimeInMs:"4000",
path:"/api/data"
}

I assumed to set the Monitor to filter on responseTimeInMs (Milli-seconds) and the path as provided - "/api/data"


# A QUICK SUMMARY OF HOW I APPROACHED THE GIVEN TEST

# PART - 1

- Implemented a sumo collector with an HTTP Endpoint as the source for logs

- Used a cURL API call  http endpoint to send logs to the collector [Simulating an application sending logs]

- Tested the API call by sending a sample log 

- Created a monitor to catch logs with responsetime more than 3000 ms(3 sec), and path matching ‘/api/data’

- Sent a burst of 7 request with a 4000 ms, which triggered the monitor alert - SUCCESS

# PART - 2

- Created  EC2, SNS Topic and Subscription, IAM Policy, IAM Role, Lambda Function resources on AWS cloud

- Deployed the Lambda function, tested it.

- Integrated the Lambda Function URL into a webhook event in the Sumo Logic platform
- Attached the webhook event in the monitor
- Sent a burst of 7 requests with a 4000 ms responseTime, which set the monitor alert, in turn triggered the lambda function - which restarted the ec2 instance, sent SNS alert; and verified SNS on email - SUCCESS

# PART - 3

- Cleaned the cloud setup from the previous part
- Created the cloud setup entirely using terraform
- Ensured the resources are created and the lambda deployed.
- Updated the lambda function url in the sumo webhook event
- Sent a burst of 7 request with a 4000 ms, which triggered the monitor alert, triggered the lambda - restarted the ec2, sent SNS alert; and I verified the notification on email - SUCCESS


# Scope for Refinements:


- Add authorization validation in the Lambda function to verify the trigger originates from Sumo Logic.
- Implement remote state file management for the terraform deployment configuration - using S3 and DynamoDB
- Improve Modularity for the terraform resources - using separate resource modules for Lambda, IAM roles/policies, SNS topic, EC2 etc.

