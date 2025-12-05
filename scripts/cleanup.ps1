# PowerShell script to destroy all AWS resources created by Terraform
# Run this script from the project root directory

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "AWS Infrastructure Cleanup Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Confirm with user
Write-Host "WARNING: This will destroy all infrastructure created by Terraform!" -ForegroundColor Yellow
Write-Host "This includes:" -ForegroundColor Yellow
Write-Host "  - EC2 instances" -ForegroundColor Yellow
Write-Host "  - Auto Scaling Group" -ForegroundColor Yellow
Write-Host "  - Application Load Balancer" -ForegroundColor Yellow
Write-Host "  - VPC and networking components" -ForegroundColor Yellow
Write-Host "  - CloudWatch logs and alarms" -ForegroundColor Yellow
Write-Host "  - All associated resources" -ForegroundColor Yellow
Write-Host ""

$confirmation = Read-Host "Type 'yes' to proceed with destruction"

if ($confirmation -ne "yes") {
    Write-Host "Cleanup cancelled." -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "Starting cleanup process..." -ForegroundColor Cyan
Write-Host ""

# Change to terraform directory
Set-Location -Path "terraform"

# Initialize Terraform (in case not already initialized)
Write-Host "Initializing Terraform..." -ForegroundColor Cyan
terraform init

# Run terraform destroy
Write-Host ""
Write-Host "Running terraform destroy..." -ForegroundColor Cyan
Write-Host ""

terraform destroy -var-file="environments/dev/terraform.tfvars" -auto-approve

# Check if destroy was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=================================" -ForegroundColor Green
    Write-Host "Cleanup completed successfully!" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "All AWS resources have been destroyed." -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: The following resources were NOT destroyed:" -ForegroundColor Yellow
    Write-Host "  - S3 bucket for Terraform state (devops-test-tfstate-*)" -ForegroundColor Yellow
    Write-Host "  - DynamoDB table for state locking (devops-test-terraform-locks)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To delete the backend resources, run:" -ForegroundColor Cyan
    Write-Host '  aws s3 rb s3://$(Get-Content ../backend-config.env | Select-String "TERRAFORM_BACKEND_BUCKET" | ForEach-Object {$_ -replace ".*=",""}) --force' -ForegroundColor Cyan
    Write-Host '  aws dynamodb delete-table --table-name $(Get-Content ../backend-config.env | Select-String "TERRAFORM_BACKEND_TABLE" | ForEach-Object {$_ -replace ".*=",""})' -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "=================================" -ForegroundColor Red
    Write-Host "Cleanup failed!" -ForegroundColor Red
    Write-Host "=================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check the error messages above and try again." -ForegroundColor Red
    Write-Host "You may need to manually delete some resources in the AWS Console." -ForegroundColor Red
}

# Return to project root
Set-Location -Path ".."

Write-Host ""
