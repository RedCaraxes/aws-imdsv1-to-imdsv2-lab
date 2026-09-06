# IMDSv1 -> IMDSv2 Terraform Lab

This lab creates:

- One VPC and public subnet
- One Amazon Linux 2023 EC2 instance
- One Security Group allowing TCP/8080 only from your IP
- One IAM role with **no resource permissions**
- One deliberately vulnerable SSRF test application
- One CloudWatch dashboard for:
  - `MetadataNoToken`
  - `MetadataNoTokenRejected`

The EC2 instance starts with:

```text
HttpTokens = optional
```

so both IMDSv1 and IMDSv2 can be tested.

## 1. Configure

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `allowed_cidr` and use your current public IPv4 address with `/32`.

Example:

```hcl
allowed_cidr = "203.0.113.10/32"
```

## 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

Get the generated commands:

```bash
terraform output test_commands
```

## 3. Phase 1 - IMDSv1 allowed

Test the application:

```bash
curl http://PUBLIC_IP:8080/health
```

Legacy IMDSv1-style request:

```bash
curl http://PUBLIC_IP:8080/legacy
```

Valid IMDSv2 request:

```bash
curl http://PUBLIC_IP:8080/v2
```

SSRF to the metadata endpoint:

```bash
curl "http://PUBLIC_IP:8080/fetch?url=http://169.254.169.254/latest/meta-data/instance-id"
```

Get the IAM role name through the same SSRF:

```bash
curl "http://PUBLIC_IP:8080/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/"
```

Do not publish real temporary credentials if you test the credential path.

The CloudWatch dashboard should start showing `MetadataNoToken` after IMDSv1 requests are emitted.

## 4. Phase 2 - Require IMDSv2

Change:

```hcl
http_tokens = "optional"
```

to:

```hcl
http_tokens = "required"
```

Then:

```bash
terraform apply
```

This updates the instance metadata option in place.

Re-run:

```bash
curl http://PUBLIC_IP:8080/legacy
```

It should fail because it does not request an IMDSv2 token.

Re-run the same SSRF:

```bash
curl "http://PUBLIC_IP:8080/fetch?url=http://169.254.169.254/latest/meta-data/instance-id"
```

The simple GET-only SSRF can no longer read metadata.

The valid IMDSv2 endpoint should still work:

```bash
curl http://PUBLIC_IP:8080/v2
```

CloudWatch can now show `MetadataNoTokenRejected` for rejected IMDSv1 attempts.

## 5. Cleanup

```bash
terraform destroy
```
