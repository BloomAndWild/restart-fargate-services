# restart-fargate-services

This is a small Serverless Framework application that will restart a given AWS Fargate Service once it goes over an 85% memory usage.

As Rails applications tend to have memory leaks, and AWS Fargate has a hard memory limit when it comes to the tasks you can run on it,
this will make sure services are gracefully restarted before they reach that limit.

## How does this work?

The project will create two alarms in Cloudwatch: one for the `admin` service and one for the `api` service. The alarm will then trigger
when the memory usage of any of the services reaches 85% or more over a period of 4 minutes.

The alarms are then piped to an SNS topic. And finally, we have a small lambda function subscribed to that SNS topic.

When the lambda executes, it inspects the payload, find out which service triggered it, and proceeds to safely restart that service in
AWS Fargate.

## How to deploy
First of all, clone the repository. Then do a `bundle install`. If you don't have the Serverless framework installed, make sure you do by
installing the npm package: `npm install serverless -g`. Finally, ensure your terminal has the AWS credentials properly configured. After
setting all this up, just run `serverless deploy` to deploy.

By default the deploy will trigger the `staging` stage. You can override this by passing in a stage parameter to the command: `serverless deploy --stage production`.

## Running the tests
The code is tested using rspec. To run the tests, simply run `bundle exec rspec`.
