# Nginx Ingress + ALB + Route53 — Production Setup on AWS EKS

## Architecture Overview

```
User (HTTPS)
    │
    ▼
Route53 (app.example.com) ──ALIAS──► ALB DNS
    │
    ▼
ALB (internet-facing, public subnets)
├── WAF v2 (OWASP rules, rate limiting, IP reputation)
├── ACM TLS termination (HTTPS:443 → HTTP:80 internally)
├── HTTP:80 → redirect to HTTPS:443
└── Access logs → S3
    │
    ▼ HTTP (internal VPC traffic only)
    │
Nginx Ingress Controller (NodePort 32080, private subnets)
├── Path routing: /app1 → app1-service
├── Path routing: /app2 → app2-service
├── Path routing: /api  → api-service
├── Canary: 20% /app1 → app1-canary-service
├── Rate limiting per IP
├── Custom 5xx error pages
└── Prometheus metrics
    │
    ├──► app1-service → app1 pods (x2)
    ├──► app2-service → app2 pods (x2)
    └──► api-service  → api pods (x2)
```

---

## Project Structure

```
nginx-ingress-demo/
├── terraform/
│   ├── main.tf          # providers, backend config
│   ├── variables.tf     # all input variables
│   ├── vpc.tf           # VPC, subnets, NAT gateway
│   ├── eks.tf           # EKS cluster + node groups
│   ├── iam.tf           # IRSA role for AWS LBC
│   ├── acm.tf           # TLS certificate + DNS validation
│   ├── route53.tf       # DNS A record → ALB
│   ├── waf.tf           # WAF v2 with OWASP rules
│   ├── s3.tf            # ALB access logs bucket
│   └── outputs.tf       # useful output values
└── helm/
    ├── aws-lbc-values.yaml        # AWS Load Balancer Controller config
    ├── nginx-ingress-values.yaml  # Nginx Ingress Controller config
    ├── apps/
    │   ├── app1.yaml              # app1 + canary deployment
    │   └── app2.yaml              # app2 + api deployment
    ├── ingress/
    │   ├── alb-ingress.yaml       # creates the ALB via AWS LBC
    │   └── nginx-ingress.yaml     # Nginx routing rules + canary
    ├── error-pages/
    │   └── custom-error-pages.yaml # custom 502/503/504 pages
    └── monitoring/
        ├── prometheus-values.yaml  # Prometheus + Grafana + Alertmanager
        └── alerts.yaml             # PrometheusRules for 5xx alerting
```

---

## Prerequisites

```bash
# Tools needed on your machine
aws --version          # AWS CLI v2
terraform --version    # >= 1.5.0
kubectl version        # >= 1.28
helm version           # >= 3.0
```

---

## Step-by-Step Setup

### Step 1 — Create Remote State Infrastructure

Before running Terraform, create the S3 bucket and DynamoDB table for state:

```bash
# Create S3 bucket for state
aws s3 mb s3://nginx-ingress-demo-tfstate --region us-east-1
aws s3api put-bucket-versioning \
  --bucket nginx-ingress-demo-tfstate \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name nginx-ingress-demo-tf-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Step 2 — Update Variables

Edit `terraform/variables.tf` and set your domain:
```hcl
variable "domain_name" {
  default = "your-actual-domain.com"   # must be in Route53
}
```

### Step 3 — Run Terraform

```bash
cd terraform/

terraform init      # download providers, connect to S3 backend
terraform plan      # review what will be created
terraform apply     # create all AWS resources (~15 minutes)
```

After apply, note the outputs:
```bash
terraform output kubeconfig_command   # configure kubectl
terraform output acm_certificate_arn  # needed for alb-ingress.yaml
terraform output waf_arn              # needed for alb-ingress.yaml
terraform output alb_logs_bucket      # needed for alb-ingress.yaml
terraform output aws_lbc_role_arn     # needed for aws-lbc-values.yaml
```

### Step 4 — Configure kubectl

```bash
# Connect kubectl to your EKS cluster
aws eks update-kubeconfig --region us-east-1 --name nginx-ingress-demo-eks

# Verify connection
kubectl get nodes
```

### Step 5 — Install AWS Load Balancer Controller

```bash
# Update aws-lbc-values.yaml with your IAM role ARN
# (from: terraform output aws_lbc_role_arn)

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  -f helm/aws-lbc-values.yaml

# Verify
kubectl get deployment -n kube-system aws-load-balancer-controller
```

### Step 6 — Install Nginx Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f helm/nginx-ingress-values.yaml

# Verify — should show 2 pods running
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### Step 7 — Update ALB Ingress with Terraform Outputs

Edit `helm/ingress/alb-ingress.yaml` and replace placeholders:
```yaml
# Replace these with actual values from terraform output
alb.ingress.kubernetes.io/certificate-arn: <ACM_CERT_ARN>
alb.ingress.kubernetes.io/wafv2-acl-arn: <WAF_ARN>
# access_logs.s3.bucket=<ALB_LOGS_BUCKET>
```

### Step 8 — Create the ALB

```bash
# This creates the actual ALB in AWS
kubectl apply -f helm/ingress/alb-ingress.yaml

# Watch ALB being provisioned (takes ~2 minutes)
kubectl get ingress -n ingress-nginx alb-to-nginx -w

# You'll see ADDRESS column fill with ALB DNS name
# e.g. k8s-ingressn-alb-xxxxx.us-east-1.elb.amazonaws.com
```

### Step 9 — Deploy Applications

```bash
kubectl apply -f helm/apps/app1.yaml
kubectl apply -f helm/apps/app2.yaml

# Verify pods are running
kubectl get pods
kubectl get svc
```

### Step 10 — Apply Nginx Routing Rules

```bash
# Update host in nginx-ingress.yaml to your domain first
kubectl apply -f helm/ingress/nginx-ingress.yaml

# Verify ingress rules
kubectl get ingress
kubectl describe ingress app-ingress
```

### Step 11 — Deploy Custom Error Pages

```bash
kubectl apply -f helm/error-pages/custom-error-pages.yaml
```

### Step 12 — Install Monitoring

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f helm/monitoring/prometheus-values.yaml

# Apply alert rules
kubectl apply -f helm/monitoring/alerts.yaml

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open http://localhost:3000 → import dashboard ID 9614
```

---

## 5xx Errors — Deep Dive Hands-On

### Understanding Each Error

| Error | Meaning | Where it happens |
|-------|---------|-----------------|
| 500 | Internal Server Error — app bug/unhandled exception | Inside the app pod (app code) |
| 502 | Bad Gateway — upstream returned invalid response | Pod crashed mid-request |
| 503 | Service Unavailable — no healthy endpoints | All pods down / no endpoints |
| 504 | Gateway Timeout — upstream too slow | App slow, timeout exceeded |
| 505 | HTTP Version Not Supported — bad HTTP version | Nginx itself (never hits pod) |

---

### Simulate and Fix 500 Internal Server Error

**What causes 500:**
- Unhandled exception in application code (NullPointerException, KeyError etc.)
- App connects to DB but query fails with no error handling
- Missing environment variable the app depends on
- Bug introduced in a new deployment

**Key difference from 502:** 500 comes FROM the app pod itself. The pod is running and responding, but returning an error. 502 means the pod gave no valid response at all.

```bash
# Simulate: deploy an app that always returns 500
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: broken-app
  template:
    metadata:
      labels:
        app: broken-app
    spec:
      containers:
      - name: broken-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        # Override nginx to always return 500
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo 'server { listen 80; location / { return 500 "App Error"; } }' \
            > /etc/nginx/conf.d/default.conf && nginx -g "daemon off;"
EOF

# Hit the endpoint — you get 500
curl -I https://app.example.com/app1

# Debug steps:
# 500 always means look at the APP logs first — not Nginx logs
kubectl logs <pod-name>                   # look for stack traces, exceptions
kubectl logs <pod-name> --previous        # if pod restarted after crash

# Check if a recent deployment introduced the bug
kubectl rollout history deployment/app1   # see deployment history
kubectl describe deployment app1          # see current image/config

# Check environment variables (missing config = common 500 cause)
kubectl exec <pod-name> -- env | grep -i db
kubectl exec <pod-name> -- env | grep -i secret

# Fix: rollback to last working version
kubectl rollout undo deployment/app1
kubectl rollout status deployment/app1
```

---

### Simulate and Fix 505 HTTP Version Not Supported

**What causes 505:**
- Client sends a request with an HTTP version Nginx doesn't support
- A misconfigured proxy/tool upstream forces an unsupported version
- Very rare in practice — but important to know

**Key difference from others:** 505 is returned BY Nginx itself. The request never reaches your app pod. It's rejected at the Nginx layer.

```bash
# Simulate: send a request with a bad HTTP version using curl
# curl --http0.9 forces HTTP/0.9 which Nginx rejects
curl -v --http0.9 https://app.example.com/app1
# You get: 505 HTTP Version Not Supported

# Another way — raw netcat request with bad version
echo -e "GET /app1 HTTP/0.9\r\nHost: app.example.com\r\n\r\n" | \
  nc app.example.com 80

# Debug steps:
# 505 shows in Nginx logs — check what HTTP version the client sent
kubectl logs -n ingress-nginx \
  -l app.kubernetes.io/name=ingress-nginx --tail=50 | grep 505

# The log will show the request line — look at the HTTP version field:
# "GET /app1 HTTP/0.9" 505  ← HTTP/0.9 is the problem
# "GET /app1 HTTP/3.0" 505  ← if client forces HTTP/3 before QUIC support

# Check ALB access logs in S3 for the client IP sending bad requests
# Use Athena to query: SELECT * FROM alb_logs WHERE elb_status_code = 505

# Fix: almost always a client-side issue
# If it's your own client/service: fix it to use HTTP/1.1 or HTTP/2
# If it's external bad actors: add WAF rule to block that IP
aws wafv2 create-ip-set \
  --name block-bad-clients \
  --scope REGIONAL \
  --ip-address-version IPV4 \
  --addresses "<BAD_CLIENT_IP>/32"
```

---

### 500 vs 502 — The Most Confused Pair

This is the most common confusion for DevOps engineers:

```
500 — App pod is RUNNING, returns error response
      Request → Nginx → Pod → Pod says "500 I have a bug"
      Debug: kubectl logs <pod>  ← look here first

502 — App pod is NOT responding properly
      Request → Nginx → Pod (crashed/bad response) → Nginx says "502"
      Debug: kubectl get pods  ← check if pod is even running
```

```bash
# Quick way to tell them apart in Nginx logs:
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=100

# 500 log line — upstream_status matches status:
# "GET /app1" 500 ... upstream_status: 500  ← pod returned 500

# 502 log line — upstream_status is different or empty:
# "GET /app1" 502 ... upstream_status: -    ← pod gave no response
# "GET /app1" 502 ... upstream_status: 000  ← connection refused
```

---

### 505 vs Other 5xx — Origin Layer Summary

```
Where does each error originate?

  Client Request
      │
      ▼
  WAF (blocks → 403, not 5xx)
      │
      ▼
  ALB
      │
      ▼
  Nginx ──── 505 originates HERE (bad HTTP version, Nginx rejects)
      │
      ▼       502 originates HERE (bad upstream response)
  App Pod     503 originates HERE (no pod available)
      │       504 originates HERE (pod too slow)
      │
      └──── 500 originates HERE (app code bug, pod returns 500)
```

---

- Pod crashes while handling a request
- Pod returns a non-HTTP response
- Pod OOMKilled (out of memory)

```bash
# Simulate: deploy a broken image
kubectl set image deployment/app1 app1=nginx:broken-does-not-exist

# Watch pods fail
kubectl get pods -w

# Hit the endpoint — you get 502
curl -I https://app.example.com/app1

# Debug steps:
kubectl get pods                          # see CrashLoopBackOff or ImagePullBackOff
kubectl describe pod <pod-name>           # see exact error reason
kubectl logs <pod-name> --previous        # logs from crashed container

# Fix: rollback to previous version
kubectl rollout undo deployment/app1

# Verify rollback
kubectl rollout status deployment/app1
```

---

### Simulate and Fix 503 Service Unavailable

**What causes 503:**
- All pods scaled to 0
- All pods failing readiness probe
- Service selector doesn't match any pods
- Endpoints object is empty

```bash
# Simulate: scale down all pods
kubectl scale deployment app1 --replicas=0

# Check endpoints — should be empty
kubectl get endpoints app1-service
# Output: app1-service   <none>   ...  ← this causes 503

# Hit the endpoint — you get 503
curl -I https://app.example.com/app1

# Debug steps:
kubectl get endpoints                     # check if endpoints exist
kubectl get pods -l app=app1             # check if pods are running
kubectl describe svc app1-service        # check selector matches pod labels

# Fix: scale back up
kubectl scale deployment app1 --replicas=2

# Watch pods become ready
kubectl get pods -w

# Verify endpoints are populated
kubectl get endpoints app1-service
# Output: app1-service   10.0.1.5:80,10.0.2.3:80   ← healthy
```

---

### Simulate and Fix 504 Gateway Timeout

**What causes 504:**
- App takes longer than proxy-read-timeout (default 60s)
- Slow database queries
- High CPU/memory causing slow responses
- Deadlocks in application

```bash
# Simulate: deploy an app that sleeps for 90 seconds
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slow-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: slow-app
  template:
    metadata:
      labels:
        app: slow-app
    spec:
      containers:
      - name: slow-app
        image: nginx:alpine
        command: ["/bin/sh", "-c"]
        args: ["sleep 90 && nginx -g 'daemon off;'"]
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: slow-app-service
spec:
  selector:
    app: slow-app
  ports:
  - port: 80
    targetPort: 80
EOF

# Add a route to slow-app in nginx-ingress.yaml and apply
# Then hit it — you get 504 after 60 seconds

# Debug steps:
kubectl top pods                          # check CPU/memory usage
kubectl logs <pod-name>                   # check app logs for slow queries

# Fix Option 1: increase timeout for this specific ingress
kubectl annotate ingress app-ingress \
  nginx.ingress.kubernetes.io/proxy-read-timeout="120"

# Fix Option 2: scale up to handle load
kubectl scale deployment app1 --replicas=5

# Fix Option 3: fix the slow query in your application code
```

---

### Nginx Ingress Logs — Reading and Understanding

```bash
# Stream Nginx Ingress logs in real time
kubectl logs -n ingress-nginx \
  -l app.kubernetes.io/name=ingress-nginx \
  -f --tail=50

# Log format (from nginx-ingress-values.yaml):
# client_ip - user [time] "METHOD /path HTTP/1.1" STATUS bytes "referer" "user-agent"
# request_time [upstream_name] upstream_ip upstream_response_time upstream_status

# Example log line:
# 1.2.3.4 - - [01/Jan/2024] "GET /app1/ HTTP/1.1" 502 0 "-" "curl/7.68"
# 0.001 [default-app1-service-80] [] 10.0.1.5:80 0 0.001 502 abc123

# Key fields to look at:
# $status              → HTTP status code (502, 503, 504)
# $upstream_status     → what the pod actually returned
# $upstream_response_time → how long pod took to respond
# $upstream_addr       → which pod IP handled the request
```

---

### Full 5xx Debugging Checklist

When you get a 5xx alert, follow this top-down approach:

```bash
# STEP 1: Check ALB target group health (is Nginx healthy?)
aws elbv2 describe-target-health \
  --target-group-arn <TG_ARN>
# If unhealthy → Nginx pods are down → check step 2

# STEP 2: Check Nginx Ingress pods
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=100

# STEP 3: Check if endpoints exist for the service
kubectl get endpoints -n default
# Empty endpoints = 503

# STEP 4: Check application pods
kubectl get pods -n default
kubectl describe pod <pod-name>    # look at Events section
kubectl logs <pod-name>            # look for errors

# STEP 5: Check ingress configuration
kubectl describe ingress app-ingress
# Look for: "Error" in events, wrong service name, wrong port

# STEP 6: Check Nginx generated config
kubectl exec -n ingress-nginx \
  $(kubectl get pod -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o name | head -1) \
  -- nginx -T | grep -A 10 "upstream default"

# STEP 7: Check Prometheus metrics
# In Grafana, look at:
# - nginx_ingress_controller_requests{status=~"5.."}  → 5xx rate
# - nginx_ingress_controller_upstream_latency_seconds → latency
```

---

## Key DevOps Points to Remember

**Deployment:**
- Always run `terraform plan` before `terraform apply`
- Use `helm upgrade --atomic` in CI/CD — rolls back automatically on failure
- Never run `kubectl apply` directly in prod — use GitOps (ArgoCD/Flux)

**Scaling:**
- Nginx Ingress HPA kicks in at 80% CPU — watch for cold start latency
- App pods need proper readiness probes — prevents 502 during deployments
- PodDisruptionBudget ensures Nginx stays up during node maintenance

**Security:**
- WAF blocks bad traffic before it hits your cluster
- TLS terminates at ALB — internal traffic is HTTP (secured by VPC/SG)
- IRSA means no AWS credentials stored in pods ever
- Rotate Grafana password — default is insecure

**Cost:**
- One ALB for all services (vs one per service without ingress) = big savings
- NAT Gateway charges per GB — keep inter-AZ traffic minimal
- WAF charges per request — monitor WAF costs in AWS Cost Explorer

**Observability:**
- Grafana dashboard 9614 = standard Nginx Ingress dashboard
- Alert on 5xx rate > 5% AND p99 latency > 2s
- ALB access logs in S3 = full audit trail, queryable with Athena
