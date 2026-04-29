# AWS Free Tier Deployment Plan: Job Portal Microservices

Deploying a 9-container microservices stack (6 Spring Boot apps + Postgres + RabbitMQ + Zipkin) on the AWS Free Tier is challenging because the standard `t2.micro` / `t3.micro` instances only provide **1 GB of RAM**. A single Spring Boot app typically consumes 256MB–512MB by default.

## Proposed Architecture for Free Tier

To make this work, we must offload the infrastructure and optimize the JVM memory usage.

### 1. Infrastructure Strategy
*   **Database**: Use **Amazon RDS (PostgreSQL)**. 
    *   *Why?* Offloads DB memory from your EC2. RDS `db.t3.micro` is Free Tier eligible (750 hrs/mo).
*   **Messaging**: Use **CloudAMQP (Free Plan)** or **AWS SQS**.
    *   *Why?* RabbitMQ in a container takes ~100-200MB RAM.
*   **Tracing**: Skip **Zipkin** or use **AWS X-Ray**.
    *   *Why?* Zipkin is memory-intensive and not critical for a functional demo.
*   **Compute**: Use one **EC2 Instance (t3.micro/t2.micro)**.

### 2. Memory Optimization (Crucial)
*   **Swap File**: Enable 2GB–4GB of Swap memory on the EC2 instance to prevent "Out of Memory" crashes.
*   **JVM Limits**: Force each container to use minimal memory:
    ```bash
    JAVA_OPTS="-Xms64m -Xmx128m -XX:MaxMetaspaceSize=64m"
    ```

---

## Proposed Changes

### EC2 & Docker Setup

#### [NEW] `aws-deployment.yml`
Create a specialized Docker Compose file for AWS that points to RDS and uses strict memory limits.

#### [NEW] `setup-ec2.sh`
A script to automate EC2 preparation: installing Docker, setting up Swap, and configuring environment variables.

---

## Step-by-Step Implementation Flow

1.  **AWS RDS Setup**:
    *   Create a PostgreSQL instance on RDS (`db.t3.micro`).
    *   Configure Security Groups to allow traffic from your EC2.
2.  **EC2 Preparation**:
    *   Launch a `t3.micro` (Amazon Linux 2023 or Ubuntu).
    *   Apply the Swap file (2GB minimum).
3.  **Docker Compose Update**:
    *   Create `aws-deployment.yml` excluding Zipkin and Postgres (since we use RDS).
    *   Inject RDS credentials via environment variables.
4.  **Network Setup**:
    *   Open ports `8085` (Gateway) and `8761` (Eureka Dashboard) in EC2 Security Group.

## Verification Plan

### Automated Tests
*   `docker compose -f aws-deployment.yml ps` to verify all 6 services are running.
*   Health check endpoints for each service.

### Manual Verification
*   Access the Eureka Dashboard via EC2 Public IP.
*   Test a Job creation/retrieval via the API Gateway.
*   Verify records are appearing in the RDS database.

## Open Questions
*   **Are you comfortable using AWS RDS?** It's the best way to save RAM on your EC2.
*   **Do you need Zipkin/Tracing for this deployment?** I recommend disabling it for the Free Tier to save ~200MB RAM.
*   **Is it okay to use a Swap file?** It makes the services slightly slower but prevents crashes.
