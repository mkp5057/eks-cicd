#!/bin/sh

AWS_ACCOUNT_ID=852760950639
REPO=eks-poc

# Step 1:ECR Repository for eks poc appication 
aws ecr create-repository \
     --repository-name  $REPO \
     --region us-east-1

aws ecr get-login-password \
     --region us-east-1 | docker login \
     --username AWS \
     --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/$REPO