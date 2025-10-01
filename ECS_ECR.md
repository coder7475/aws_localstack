# Structured Learning Plan: AWS ECR and ECS with LocalStack

This document provides a detailed, step-by-step guide to exploring Amazon Elastic Container Registry (ECR) and Amazon Elastic Container Service (ECS) using LocalStack, a local AWS cloud emulator. The plan is divided into phases, each building progressively on the previous one. Prerequisites include:

- Docker installed and running on your local machine.
- AWS CLI installed and configured (use a dummy profile for LocalStack).
- LocalStack installed via `pip install localstack` or Docker, and started with `localstack start` (enable ECR and ECS services via `SERVICES=ecr,ecs localstack start`).

All commands assume you are using the AWS CLI with the LocalStack endpoint (`--endpoint-url=http://localhost:4566`). Proceed sequentially to ensure foundational knowledge is solidified before advancing.

---

## Phase 1: Foundations (ECR Basics)

### Step 1: Understand ECR Concepts

- **Elastic Container Registry (ECR)**: A fully managed Docker container registry that makes it easy to store, manage, and deploy Docker container images. It supports private repositories for secure image storage.
- **Authentication and Repository Structure**: Access requires temporary AWS credentials; repositories are organized by AWS account and region, with policies for permissions.
- **Comparison with Docker Hub**: ECR is AWS-native, integrates seamlessly with ECS, and offers private repositories with fine-grained access control, unlike Docker Hub's public focus and simpler authentication.

Read the official ECR documentation for deeper insights.

### Step 2: Hands-On with ECR in LocalStack

1. **Create an ECR Repository**:

   - Run: `aws ecr create-repository --repository-name my-app-repo --endpoint-url=http://localhost:4566`
   - Verify: `aws ecr describe-repositories --repository-names my-app-repo --endpoint-url=http://localhost:4566`

2. **Authenticate Docker with LocalStack ECR**:

   - Obtain the login password: `aws ecr get-login-password --region us-east-1 --endpoint-url=http://localhost:4566 | docker login --username AWS --password-stdin 000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4510`
   - Note: Replace `000000000000` with your AWS account ID (use `aws sts get-caller-identity`).

3. **Build, Tag, and Push a Docker Image**:

   - Create a simple Dockerfile: `FROM nginx:latest` (save as `Dockerfile`).
   - Build: `docker build -t my-nginx .`
   - Tag: `docker tag my-nginx:latest 000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4510/my-app-repo:latest`
   - Push: `docker push 000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4510/my-app-repo:latest`

4. **Pull the Image Back and Run It Locally**:
   - Pull: `docker pull 000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4510/my-app-repo:latest`
   - Run: `docker run -p 8080:80 000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4510/my-app-repo:latest`
   - Verify: Access `http://localhost:8080` in a browser to see the NGINX welcome page.

---

## Phase 2: ECS Fundamentals

### Step 1: Understand ECS Concepts

- **ECS Launch Types**: EC2 launch type uses your own EC2 instances for hosting tasks; Fargate is serverless, abstracting infrastructure management.
- **Core Components**:
  - **Task Definition**: A blueprint specifying container images, CPU/memory, and environment.
  - **Service**: Manages long-running tasks, ensuring desired replicas.
  - **Cluster**: A logical grouping of resources for tasks/services.
- **Image Pulling**: ECS tasks automatically pull images from ECR during launch, requiring proper IAM permissions.

Review ECS documentation for architectural diagrams.

### Step 2: Hands-On ECS with LocalStack

1. **Create an ECS Cluster**:

   - Run: `aws ecs create-cluster --cluster-name my-cluster --endpoint-url=http://localhost:4566`
   - Verify: `aws ecs describe-clusters --clusters my-cluster --endpoint-url=http://localhost:4566`

2. **Register a Task Definition Using the ECR Image**:

   - Create a JSON file `task-definition.json`:
     ```
     {
       "family": "my-task",
       "networkMode": "bridge",
       "containerDefinitions": [
         {
           "name": "nginx-container",
           "image": "000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4510/my-app-repo:latest",
           "portMappings": [{ "containerPort": 80 }],
           "memory": 512
         }
       ],
       "requiresCompatibilities": ["EC2"]
     }
     ```
   - Register: `aws ecs register-task-definition --cli-input-json file://task-definition.json --endpoint-url=http://localhost:4566`

3. **Run the Task on the Cluster**:

   - Run: `aws ecs run-task --cluster my-cluster --task-definition my-task --count 1 --launch-type EC2 --endpoint-url=http://localhost:4566`
   - Verify: `aws ecs describe-tasks --cluster my-cluster --tasks $(aws ecs list-tasks --cluster my-cluster --query 'taskArns[0]' --output text) --endpoint-url=http://localhost:4566`

4. **Check Logs and Verify Container Execution**:
   - List tasks: `aws ecs list-tasks --cluster my-cluster --endpoint-url=http://localhost:4566`
   - In LocalStack, logs are simulated; use `docker logs` if running via Docker Compose, or inspect task status for exit codes.
   - Confirm: Task status should be "RUNNING" or "STOPPED" with no errors.

---

## Phase 3: ECS Services and Scaling

### Step 1: Service Basics

- **Task vs. Service**: A task is a one-time or short-lived execution; a service maintains a specified number of tasks for ongoing operations.
- **Scaling**: Services support auto-scaling based on metrics like CPU utilization, allowing multiple replicas for high availability.

### Step 2: Hands-On with ECS Service in LocalStack

1. **Deploy a Service Running Multiple Tasks**:

   - Create `service-definition.json`:
     ```
     {
       "cluster": "my-cluster",
       "serviceName": "my-service",
       "taskDefinition": "my-task",
       "desiredCount": 2,
       "launchType": "EC2"
     }
     ```
   - Create: `aws ecs create-service --cli-input-json file://service-definition.json --endpoint-url=http://localhost:4566`

2. **Attach Networking (Bridge Mode in LocalStack)**:

   - Update task definition if needed to include `"networkMode": "bridge"`.
   - Rerun the service creation with the updated definition.

3. **Test Service Accessibility**:
   - Describe service: `aws ecs describe-services --cluster my-cluster --services my-service --endpoint-url=http://localhost:4566`
   - In LocalStack, simulate access via port mapping; use `docker port` to check exposed ports and curl `http://localhost:8080` for verification.

---

## Phase 4: Real-World Simulation

### Step 1: Mini Project – Deploy a Simple App

1. **Containerize a Node.js or Python App**:

   - For Node.js: Create `app.js` with `const http = require('http'); http.createServer((req, res) => { res.writeHead(200); res.end('Hello from ECS!'); }).listen(3000);`
   - Dockerfile: `FROM node:14; COPY app.js .; CMD ["node", "app.js"]`
   - Build and push as in Phase 1, updating the repository/image tag.

2. **Push to LocalStack ECR**:

   - Tag: `docker tag my-app:latest 000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4510/my-app-repo:v1`
   - Push: `docker push 000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4510/my-app-repo:v1`

3. **Deploy via ECS Task Definition**:

   - Update `task-definition.json` with new image and port 3000.
   - Register and run task as in Phase 2.

4. **Expose with ECS Service + LocalStack Networking**:
   - Update service to desired count 1, with port mappings.
   - Test: `curl http://localhost:3000`

### Step 2: Scaling and Monitoring

1. **Run Multiple Replicas**:

   - Update service: `aws ecs update-service --cluster my-cluster --service my-service --desired-count 3 --endpoint-url=http://localhost:4566`

2. **Check Logs and Service Health**:
   - Monitor: `aws ecs describe-services --cluster my-cluster --services my-service --endpoint-url=http://localhost:4566`
   - In LocalStack, health checks are basic; observe running count and task statuses for simulated monitoring.

---

## Phase 5: Wrap-Up and Next Steps

1. **Document the Workflow**:

   - Summarize: Docker build/tag/push → ECR repository storage → ECS task definition registration → ECS service deployment for orchestration.

2. **Compare LocalStack ECS vs. Real AWS ECS**:

   - LocalStack: Local simulation, no real compute; ideal for development/testing.
   - AWS: Full scalability, IAM integration, CloudWatch logging; requires VPC configuration.

3. **Prepare Migration Steps**:
   - Update endpoints to AWS regions (e.g., `--region us-east-1` without LocalStack URL).
   - Replace dummy credentials with real IAM roles.
   - Enable CloudWatch for logs and ALB for load balancing.
   - Test incrementally: Start with ECR push, then ECS cluster creation.

Upon completion, you will possess practical expertise in managing container images via ECR and orchestrating deployments with ECS, all within a local environment. This foundation facilitates efficient prototyping and reduces costs during development. For advanced topics, explore LocalStack's ECS Fargate simulation or integrate with CI/CD pipelines.
