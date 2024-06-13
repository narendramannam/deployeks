# EKS Cluster Setup with Terraform and Kubernetes Manifests

The module includes IaC and manifests code to setup a network, deploy an opinionated EKS cluster and run a demo application with a minimal required controllers.

## Prerequisites

- AWS CLI installed and configured
- Terraform installed
- kubectl installed
- jq installed (for JSON parsing)
- AWS account with necessary permissions
- IAM user/role with permissions to create resources

## Export AWS Keys

First, export your AWS access keys as environment variables:

```sh
export AWS_ACCESS_KEY_ID=<your-access-key-id>
export AWS_SECRET_ACCESS_KEY=<your-secret-access-key>
export AWS_REGION=<your-aws-region>
```
Verify AWS credentials are valid and pointing to correct account:
```sh
aws sts get-caller-identity
```

## Terraform workflow
Initialize and validate terraform code

```sh
terraform init
terraform fmt -check
terraform validate
tflint
```

Run terraform plan, review and apply to create network, cluster and deploy k8s controllers to the EKS cluster
```sh
terraform plan -out=tfplan
terraform apply tfplan --auto-approve
terraform output -json > tf_output.json
```

## Export and deploy Nginx application
For this demo, let's use nginx image to deploy and configure, scaling and ingress in-order to access from internet
 
**Note:** Update certificate ARN and ingress hostname in nginx.yaml to set the values to `alb.ingress.kubernetes.io/certificate-arn` and `external-dns.alpha.kubernetes.io/hostname` respectively before deploying
- Validate manifests
```sh
cd nginx-app
kubectl apply -f nginx.yaml --dry-run=client
```
- Apply k8s manifests
```sh
kubectl apply -f nginx.yaml
```
- View resources
```sh
kubectl get all,ing -n nginx
```
- Verify the endpoint
```sh
curl -I http://${DNS_HOSTNAME}/
```

## Cleanup
In-order to clean-up the resources delete the k8s resources and run terraform destroy
- Delete nginx resources from cluster
```sh
cd nginx-app
kubectl delete -f nginx.yaml
```
- Remove EKS infrastructure and network
```sh
cd infrastructure
terraform destroy --auto-approve
```