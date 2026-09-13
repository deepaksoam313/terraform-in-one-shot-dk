# 07 - Remote State

## What you learn here
- Why local state is dangerous in teams
- How to store state remotely in S3
- How to prevent concurrent applies with DynamoDB state locking
- The bootstrap pattern (create the backend infra first)

---

## The Problem with Local State

By default Terraform writes state to a local `terraform.tfstate` file.

Problems in a team:
- Two people run `terraform apply` at the same time → state corruption
- Someone deletes their local state → Terraform loses track of infra
- No history, no versioning, no sharing

---

## The Solution — Remote State (S3 + DynamoDB)

| Component | Role |
|---|---|
| S3 bucket | Stores the `terraform.tfstate` file remotely |
| S3 versioning | Keeps history of every state change |
| DynamoDB table | Locks state during apply — prevents concurrent runs |

---

## Backend Block

```hcl
terraform {
  backend "s3" {
    bucket         = "my-state-bucket"
    key            = "project/terraform.tfstate"   # path inside bucket
    region         = "us-east-1"
    dynamodb_table = "my-state-lock"
    encrypt        = true
  }
}
```

The `key` is the path inside the S3 bucket where the state file lives.
Use different keys per project/environment:
- `dev/terraform.tfstate`
- `prod/terraform.tfstate`

---

## How State Locking Works

1. You run `terraform apply`
2. Terraform writes a lock entry to DynamoDB (`LockID`)
3. If someone else runs `terraform apply` at the same time → they see the lock and wait
4. When your apply finishes → lock is released

---

## Folder Structure

```
07-remote-state/
├── bootstrap/          ← Run ONCE to create the S3 bucket + DynamoDB table
│   ├── main.tf
│   └── outputs.tf
├── main.tf             ← Your actual project using the remote backend
├── outputs.tf
└── README.md
```

---

## Step-by-Step Usage

### Step 1 — Create the backend infrastructure first (run once)
```bash
cd 07-remote-state/bootstrap
terraform init
terraform apply
```

### Step 2 — Use the remote backend in your project
```bash
cd 07-remote-state
terraform init    # Terraform will ask to migrate state to S3
terraform plan
terraform apply
terraform output
```

### Step 3 — Verify state is in S3
Go to AWS Console → S3 → your bucket → you'll see `07-remote-state/terraform.tfstate`

---

## Important Notes

- **Never commit `terraform.tfstate`** to git — it contains sensitive values
- The bootstrap S3 bucket has `prevent_destroy = true` — safety net against accidental deletion
- Always enable versioning and encryption on the state bucket
- Use a unique `key` per project so multiple projects can share the same backend bucket

---

## Files
- `bootstrap/main.tf`  → creates S3 bucket + DynamoDB table
- `bootstrap/outputs.tf` → outputs bucket and table names
- `main.tf`            → project using the remote backend
- `outputs.tf`         → project outputs
