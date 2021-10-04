# AWS EKS Infrastructure creation using Cloud formation and POC Application Deployment

## Pre-requisite:
- Set up 
  ```
  Install docker desktop, install aws cli, install kubectl, insall eksctl
  ```
- Create Dedicated VPC for the EKS Cluster

  Stack name 		: **eks-vpc** 
  ```
  CloudFormation Template: 
  0_eks-vpc.yaml
  ```  
- Create ECR Repository and authenticate Docker

  Repository name : **eks-poc**
  
  - [x] **Update script placeholder XXXXXXXXXXXX with AWS ACCOUNT ID and Execute below script**
  ```
  ./infra/5_ecr.sh
  ```  

## High Level Tasks
- Step A : Create EKS Cluster using Cloud formation - Infrastructure
  - Step 1: Create IAM role for EKS Cluster  
  - Step 2: Create EKS Cluster
- Step B : Create EKS Worker Nodes using Cloud formation - Infrastructure
  - Step 3: Create IAM Role for EKS Worker Nodes
  - Step 4: Create Worker nodes
- Step C : Deploy POC application using AWS codepipeline and kubernetes manifest file
  - Step 5: First code pipeline to push docker image to ECR    
  - Step 6: Second code pipeline to deploy docker image on EKS cluster using kubernetes manifest file
- Step D : Delete Resouces
    - Step 7: Delete Infra and deployed application
      - Step 7.1: undeploy application from EKS cluster
      - Step 7.2: Delete eks infrastructure (cloudformation stacks)
  
## Step A: Create EKS Cluster using Cloud formation - Infrastructure

### Step 1: Create IAM role for EKS Cluster 

Stack name: **eksClusterRole**
```
CloudFormation Template:  
1_eksClusterRole.yaml
```

### Step 2: Create EKS Cluster
Stack name 		: **eks-cluster** 
Cluster name 	: **eks-cluster**

 - [x] **Note: Get parameters values from output of cloud formation stack created above ( Pre-requisite: eks-vpc and Step 1: eksClusterRole stack)**
```
CloudFormation Template:  
2_ekscluster.yaml
```

**Test Cluster**
 - [x] **Note : install aws cli and install kubectl on your local machine**
```
aws  eks --region us-east-1 update-kubeconfig --name eks-cluster
kubectl get svc
```

## Step B : Create EKS Worker Nodes using Cloud formation - Infrastructure

### Step 3: Create IAM Role for EKS Worker Nodes
Stack name 		: **eksWorkerNodeGroupRole** 

Below  template will create amazon eks nodegroup role along with needed Node group cluster autoscaler policy
```
CloudFormation Template:  
3_eks-nodegroup-role.yaml
```

### Step 4: Create Worker nodes
Stack name 		: **eks-worker-node-group** 

```
CloudFormation Template:  
4_eks-nodegroup.yaml
```

**Test worker nodes**
```
kubectl get nodes -o wide
```

## Step C : Deploy POC application using AWS codepipeline and kubernetes manifest file

### Step 5: First code pipeline to push docker image to ECR 

- Create code pipeline with source as GitHub and code build as build agent which will push docker image to ECR repo
  	First and foremost, you need a git repository to store the source code. I’m using GitHub here. It contains the following in the root directory:
    
    code : The source code to be containerised whenever there is an update.
    dockerFile: File for creating custom docker image.
    buildspec.yaml file: Contains the instructions to be used by CodeBuild later on in the pipeline stages.

    Once any code changes are made to the GitHub repository, a docker container needs to be created based on instructions in Dockerfile and should be pushed to a container registry, which in this case is Elastic Container Registry

  ```
    Pipeline name: ecr-pipeline
    Service role: New service role
    Make sure that Allow AWS CodePipeline to create a service role so it can be used with this new pipeline is selected.
    Click Next
    Source Provider: GitHub
    Repository name: The repository in which the code resides.
    Branch name: The branch name
    Leave everything else as default and click Next.
    Build Provider: AWS CodeBuild
    Click Create Project
    Give Project Name as ecr-project
    Environment image: Managed image
    Operating System: Amazon Linux 2
    Runtime: Standard
    Image: aws/codebuild/amazonlinux2-x86_64-standard:2.0
    Service role: New service role
    Role name: Give a role name
    Expand Additional Configuration.
    Give these environment variables:
      AWS_DEFAULT_REGION: us-east-1
      AWS_ACCOUNT_ID: <your-aws-account-id>
      ENV: latest #use other environment name based on the type; eg., staging
      IMAGE_REPO_NAME: web-app #The container image name I intent to use
    Under Build specifications, select Use a buildspec file.
    Make other required changes and select Continue to CodePipeline.
    Back in the CodePipeline page, click Next.
    In the deployment stage, click Skip deploy stage.
    Review and select Create pipeline.
  ```
  You can alternatively create a YAML/JSON file for CodePipeline and CodeBuild for simplicity if you need to apply this for a number of pipelines

### Step 6: Second code pipeline to deploy docker image on EKS cluster using kubernetes manifest file
  
- Create code pipeline with source as GitHub and code build as build agent which will pick the docker image from ECR and deploy to 
  EKS cluster using kubernetes manifest file 

  For this pipeline, we need two source (which starts the trigger for the pipeline):
  - Whenever there is a new image in container registry, it should be applied to our already existing Kubernetes deployment.
  - If there is a change to our Kubernetes deployment manifests, that too should be applied to the deployment
  
  I’m using same GitHub repo here. It contains following additional in the root directory:
    
    eks_cicd : This directory contain all kubernetes manifest file and additonl role creation scripts used by this pipeline to deploy application in eks cluster.
    buildspec_eks.yaml file: Contains the instructions to be used by CodeBuild later on in the pipeline stages for eks deployment.


  ```
    Pipeline name: eks-pipeline
    Service role: New service role
    Make sure that Allow AWS CodePipeline to create a service role so it can be used with this new pipeline is selected.
    Click Next
    Source Provider: GitHub
    Repository name: The repository in which the code resides
    Image tag: latest
    Click Next.
    Build Provider: AWS CodeBuild
    Click Create Project
    Give Project Name as eks-project
    Environment image: Managed image
    Operating System: Amazon Linux 2
    Runtime: Standard
    Image: aws/codebuild/amazonlinux2-x86_64-standard:2.0
    Service role: Existing service role
    Role ARN: Select the ARN corresponding to codebuild-eks role
    Make sure that Allow AWS CodeBuild to modify this service role so it can be used with this build project is selected.
    Expand Additional Configuration.
    Give these environment variables:
      AWS_DEFAULT_REGION: us-east-1
      AWS_CLUSTER_NAME: <your-cluster-name>
      AWS_ACCOUNT_ID: <your-account-id>
      IMAGE_REPO_NAME: ECR repo name where docker iamges are hosted
      IMAGE_TAG: latest
    Under Build specifications, select Use a buildspec_eks file.
    Make other required changes and select Continue to CodePipeline.
    Back in the CodePipeline page, click Next.
    In the deployment stage, click Skip deploy stage.
    Review and select Create pipeline.

  ```

**Test**

```
kubectl get svc eks-demo
http://<External IP Address>
```
      
## Step D : Delete Resouces

### Step 7: Delete Infra and deployed application
- Step 7.1: undeploy eks-demo appliction for eks cluster
- Step 8.2: Delete eks infrastructure (cloudformation stacks)
	```
	eks-worker-node-group
	eksWorkerNodeGroupRole
	eks-cluster
	eksClusterRole
	eks-vpc
	```
	
## References

- Commands
  ```
  $ kubectl get deploy
  $ kubectl get svc
  $ kubectl get pod

  kubectl  logs "${POD}"

  aws cloudformation delete-stack --stack-name <my-vpc-stack>
  
  kubectl scale deployment eks-poc --replicas=3
  ```
- Links
  ```
  https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html
  ```