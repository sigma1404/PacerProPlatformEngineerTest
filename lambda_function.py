import boto3
import os
import time

ec2 = boto3.client('ec2')
sns = boto3.client('sns')

def lambda_handler(event, context):

    ec2_instance_id = os.environ['EC2_INSTANCE_ID']
    sns_topic_arn = os.environ['SNS_ARN']

    try:

        # Stop the EC2 instance
        print(f"Stopping EC2 instance: {ec2_instance_id}")
        ec2.stop_instances(InstanceIds=[ec2_instance_id])


        # Wait until the instance is stopped
        print(f"Waiting for EC2 instance {ec2_instance_id} to stop...")
        waiter = ec2.get_waiter('instance_stopped')
        waiter.wait(InstanceIds=[ec2_instance_id])

        print(f"EC2 instance {ec2_instance_id} has been stopped.")

        # Start the EC2 instance
        print(f"Starting EC2 instance: {ec2_instance_id}")
        ec2.start_instances(InstanceIds=[ec2_instance_id])

        # Wait until the instance is running
        print(f"Waiting for EC2 instance {ec2_instance_id} to start...")
        waiter = ec2.get_waiter('instance_running')
        waiter.wait(InstanceIds=[ec2_instance_id])

        print(f"EC2 instance {ec2_instance_id} is now running.")

        # Send notification via SNS
        message = f"EC2 instance {ec2_instance_id} has been restarted successfully."
        print(f"Sending notification to SNS topic: {sns_topic_arn}")
        sns.publish(
            TopicArn=sns_topic_arn,
            Subject="EC2 Instance Restarted",
            Message=message
        )

        print("SNS Notification sent.")
        print("Success")

    except Exception as e:
        print(f"Error: {str(e)}")
        sns.publish(
            TopicArn=sns_topic_arn,
            Subject="EC2 Instance Restart Failed",
            Message=f"Failed to restart EC2 instance {ec2_instance_id}. Error: {str(e)}"
        )
        raise e
