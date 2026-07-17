<#
.SYNOPSIS
    Deploys the PAYI API to AWS ECS Fargate.

.DESCRIPTION
    This script automates the full AWS deployment:
    1. Creates ECR repository
    2. Builds and pushes Docker image
    3. Creates ECS cluster, ALB, task definition, and service
    4. Stores secrets in SSM Parameter Store
    5. Outputs the public URL

.PARAMETER Region
    AWS region (default: us-east-1)

.PARAMETER ClusterName
    ECS cluster name (default: payi-cluster)

.PARAMETER ServiceName
    ECS service name (default: payi-service)

.EXAMPLE
    .\deploy\aws-deploy.ps1
    .\deploy\aws-deploy.ps1 -Region eu-west-1
#>

param(
    [string]$Region = "us-east-1",
    [string]$ClusterName = "payi-cluster",
    [string]$ServiceName = "payi-service",
    [string]$ImageName = "payi-api",
    [string]$VpcId = "",
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# ── Colors ──
function Write-Step($msg) { Write-Host "`n🔵 $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "❌ $msg" -ForegroundColor Red }

# ── Pre-flight checks ──
Write-Step "Pre-flight checks"

$awsCli = Get-Command aws -ErrorAction SilentlyContinue
if (-not $awsCli) {
    Write-Err "AWS CLI not found. Install from https://aws.amazon.com/cli/"
    exit 1
}

$dockerCli = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCli) {
    Write-Err "Docker not found. Install Docker Desktop from https://docker.com"
    exit 1
}

# Get AWS Account ID
$AccountId = (aws sts get-caller-identity --query "Account" --output text --region $Region 2>$null)
if (-not $AccountId) {
    Write-Err "Could not get AWS account ID. Run 'aws configure' first."
    exit 1
}
Write-Ok "AWS Account: $AccountId | Region: $Region"

$EcrUri = "$AccountId.dkr.ecr.$Region.amazonaws.com"
$ImageUri = "$EcrUri/${ImageName}:latest"

# ── Step 1: Create ECR Repository ──
Write-Step "Step 1: Creating ECR repository '$ImageName'"

$existingRepo = $null
try { $existingRepo = aws ecr describe-repositories --repository-names $ImageName --region $Region 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } } catch {}
if (-not $existingRepo) {
    aws ecr create-repository `
        --repository-name $ImageName `
        --region $Region `
        --image-scanning-configuration scanOnPush=true `
        --encryption-configuration encryptionType=AES256 | Out-Null
    Write-Ok "ECR repository created"
} else {
    Write-Ok "ECR repository already exists"
}

# ── Step 2: Build and Push Docker Image ──
if (-not $SkipBuild) {
    Write-Step "Step 2: Building Docker image"

    $projectRoot = Split-Path -Parent $PSScriptRoot
    Push-Location $projectRoot

    docker build -t "${ImageName}:latest" .
    if ($LASTEXITCODE -ne 0) { Write-Err "Docker build failed"; Pop-Location; exit 1 }

    Write-Step "Pushing to ECR"
    cmd /c "aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $EcrUri"
    docker tag "${ImageName}:latest" $ImageUri
    docker push $ImageUri
    if ($LASTEXITCODE -ne 0) { Write-Err "Docker push failed"; Pop-Location; exit 1 }

    Pop-Location
    Write-Ok "Image pushed: $ImageUri"
} else {
    Write-Ok "Skipping build (using existing image)"
}

# ── Step 3: Store Secrets in SSM Parameter Store ──
Write-Step "Step 3: Checking SSM parameters for secrets"

$ssmParams = @(
    @{ Name = "/payi/clerk-authority";        Default = "https://prime-puma-19.clerk.accounts.dev" },
    @{ Name = "/payi/jwt-signing-key";        Default = "" },
    @{ Name = "/payi/stripe-secret-key";      Default = "" },
    @{ Name = "/payi/stripe-publishable-key"; Default = "" }
)

foreach ($param in $ssmParams) {
    $existing = $null
    try { $existing = aws ssm get-parameter --name $param.Name --region $Region 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } } catch {}
    if (-not $existing) {
        if ($param.Default) {
            aws ssm put-parameter `
                --name $param.Name `
                --value $param.Default `
                --type SecureString `
                --region $Region | Out-Null
            Write-Ok "Created SSM parameter: $($param.Name) (with default)"
        } else {
            Write-Warn "SSM parameter $($param.Name) does not exist. Create it manually:"
            Write-Host "  aws ssm put-parameter --name '$($param.Name)' --value 'YOUR_VALUE' --type SecureString --region $Region"
        }
    } else {
        Write-Ok "SSM parameter exists: $($param.Name)"
    }
}

# ── Step 4: Create CloudWatch Log Group ──
Write-Step "Step 4: Creating CloudWatch log group"

try { aws logs create-log-group --log-group-name "/ecs/payi-api" --region $Region 2>&1 | Out-Null } catch {}
Write-Ok "Log group /ecs/payi-api ready"

# ── Step 5: Create ECS Cluster ──
Write-Step "Step 5: Creating ECS cluster '$ClusterName'"

$existingCluster = aws ecs describe-clusters --clusters $ClusterName --region $Region --query "clusters[?status=='ACTIVE'].clusterName" --output text 2>$null
if ($existingCluster -ne $ClusterName) {
    aws ecs create-cluster --cluster-name $ClusterName --region $Region | Out-Null
    Write-Ok "ECS cluster created"
} else {
    Write-Ok "ECS cluster already exists"
}

# ── Step 6: Get or Create VPC and Subnets ──
Write-Step "Step 6: Resolving VPC and subnets"

if (-not $VpcId) {
    $VpcId = aws ec2 describe-vpcs `
        --filters "Name=is-default,Values=true" `
        --query "Vpcs[0].VpcId" `
        --output text `
        --region $Region
}
Write-Ok "VPC: $VpcId"

$SubnetIds = aws ec2 describe-subnets `
    --filters "Name=vpc-id,Values=$VpcId" `
    --query "Subnets[*].SubnetId" `
    --output text `
    --region $Region
$SubnetList = ($SubnetIds -split "`t") | Select-Object -First 2
Write-Ok "Subnets: $($SubnetList -join ', ')"

# ── Step 7: Create Security Groups ──
Write-Step "Step 7: Creating security groups"

# ALB Security Group
$AlbSgId = $null
try { $AlbSgId = aws ec2 describe-security-groups `
    --filters "Name=group-name,Values=payi-alb-sg" "Name=vpc-id,Values=$VpcId" `
    --query "SecurityGroups[0].GroupId" `
    --output text `
    --region $Region 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } } catch {}

if ($AlbSgId -eq "None" -or -not $AlbSgId) {
    $AlbSgId = aws ec2 create-security-group `
        --group-name "payi-alb-sg" `
        --description "PAYI ALB - HTTP/HTTPS inbound" `
        --vpc-id $VpcId `
        --region $Region `
        --query "GroupId" `
        --output text

    aws ec2 authorize-security-group-ingress --group-id $AlbSgId --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $Region | Out-Null
    aws ec2 authorize-security-group-ingress --group-id $AlbSgId --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $Region | Out-Null
    Write-Ok "ALB security group created: $AlbSgId"
} else {
    Write-Ok "ALB security group exists: $AlbSgId"
}

# ECS Task Security Group
$TaskSgId = $null
try { $TaskSgId = aws ec2 describe-security-groups `
    --filters "Name=group-name,Values=payi-ecs-sg" "Name=vpc-id,Values=$VpcId" `
    --query "SecurityGroups[0].GroupId" `
    --output text `
    --region $Region 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } } catch {}

if ($TaskSgId -eq "None" -or -not $TaskSgId) {
    $TaskSgId = aws ec2 create-security-group `
        --group-name "payi-ecs-sg" `
        --description "PAYI ECS Tasks - port 8080 from ALB only" `
        --vpc-id $VpcId `
        --region $Region `
        --query "GroupId" `
        --output text

    aws ec2 authorize-security-group-ingress --group-id $TaskSgId --protocol tcp --port 8080 --source-group $AlbSgId --region $Region | Out-Null
    Write-Ok "ECS security group created: $TaskSgId"
} else {
    Write-Ok "ECS security group exists: $TaskSgId"
}

# ── Step 8: Create Application Load Balancer ──
Write-Step "Step 8: Creating Application Load Balancer"

$AlbArn = $null
try { $AlbArn = aws elbv2 describe-load-balancers `
    --names "payi-alb" `
    --query "LoadBalancers[0].LoadBalancerArn" `
    --output text `
    --region $Region 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } } catch {}

if (-not $AlbArn -or $AlbArn -eq "None") {
    $subnetArgs = ($SubnetList | ForEach-Object { $_ }) -join " "

    $AlbArn = aws elbv2 create-load-balancer `
        --name "payi-alb" `
        --subnets $SubnetList `
        --security-groups $AlbSgId `
        --scheme internet-facing `
        --type application `
        --region $Region `
        --query "LoadBalancers[0].LoadBalancerArn" `
        --output text

    Write-Ok "ALB created: $AlbArn"
} else {
    Write-Ok "ALB already exists: $AlbArn"
}

$AlbDns = aws elbv2 describe-load-balancers `
    --load-balancer-arns $AlbArn `
    --query "LoadBalancers[0].DNSName" `
    --output text `
    --region $Region

# ── Step 9: Create Target Group ──
Write-Step "Step 9: Creating target group"

$TgArn = $null
try { $TgArn = aws elbv2 describe-target-groups `
    --names "payi-tg" `
    --query "TargetGroups[0].TargetGroupArn" `
    --output text `
    --region $Region 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } } catch {}

if (-not $TgArn -or $TgArn -eq "None") {
    $TgArn = aws elbv2 create-target-group `
        --name "payi-tg" `
        --protocol HTTP `
        --port 8080 `
        --vpc-id $VpcId `
        --target-type ip `
        --health-check-path "/api/system/health" `
        --health-check-interval-seconds 30 `
        --healthy-threshold-count 2 `
        --unhealthy-threshold-count 3 `
        --region $Region `
        --query "TargetGroups[0].TargetGroupArn" `
        --output text

    Write-Ok "Target group created: $TgArn"
} else {
    Write-Ok "Target group already exists: $TgArn"
}

# ── Step 10: Create ALB Listener ──
Write-Step "Step 10: Creating ALB listener (HTTP:80)"

$ListenerArn = $null
try { $ListenerArn = aws elbv2 describe-listeners `
    --load-balancer-arn $AlbArn `
    --query "Listeners[?Port==\`80\`].ListenerArn" `
    --output text `
    --region $Region 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } } catch {}

if (-not $ListenerArn -or $ListenerArn -eq "None") {
    aws elbv2 create-listener `
        --load-balancer-arn $AlbArn `
        --protocol HTTP `
        --port 80 `
        --default-actions "Type=forward,TargetGroupArn=$TgArn" `
        --region $Region | Out-Null
    Write-Ok "HTTP listener created"
} else {
    Write-Ok "HTTP listener already exists"
}

# ── Step 11: Create IAM Roles (if needed) ──
Write-Step "Step 11: Checking IAM roles"

$executionRole = $null
try { $executionRole = aws iam get-role --role-name ecsTaskExecutionRole --query "Role.Arn" --output text 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } } catch {}
if (-not $executionRole) {
    Write-Warn "ecsTaskExecutionRole does not exist. Creating..."

    $trustPolicy = @{
        Version = "2012-10-17"
        Statement = @(@{
            Effect = "Allow"
            Principal = @{ Service = "ecs-tasks.amazonaws.com" }
            Action = "sts:AssumeRole"
        })
    } | ConvertTo-Json -Depth 5

    $trustPolicyFile = [System.IO.Path]::GetTempFileName()
    $trustPolicy | Set-Content -Path $trustPolicyFile

    aws iam create-role `
        --role-name ecsTaskExecutionRole `
        --assume-role-policy-document "file://$trustPolicyFile" | Out-Null

    aws iam attach-role-policy `
        --role-name ecsTaskExecutionRole `
        --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" | Out-Null

    # Allow reading SSM parameters for secrets
    aws iam attach-role-policy `
        --role-name ecsTaskExecutionRole `
        --policy-arn "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess" | Out-Null

    Remove-Item $trustPolicyFile
    $executionRole = aws iam get-role --role-name ecsTaskExecutionRole --query "Role.Arn" --output text
    Write-Ok "Created ecsTaskExecutionRole: $executionRole"
} else {
    Write-Ok "ecsTaskExecutionRole exists: $executionRole"
}

$taskRole = $null
try { $taskRole = aws iam get-role --role-name ecsTaskRole --query "Role.Arn" --output text 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } } catch {}
if (-not $taskRole) {
    Write-Warn "ecsTaskRole does not exist. Creating..."

    $trustPolicy = @{
        Version = "2012-10-17"
        Statement = @(@{
            Effect = "Allow"
            Principal = @{ Service = "ecs-tasks.amazonaws.com" }
            Action = "sts:AssumeRole"
        })
    } | ConvertTo-Json -Depth 5

    $trustPolicyFile = [System.IO.Path]::GetTempFileName()
    $trustPolicy | Set-Content -Path $trustPolicyFile

    aws iam create-role `
        --role-name ecsTaskRole `
        --assume-role-policy-document "file://$trustPolicyFile" | Out-Null

    Remove-Item $trustPolicyFile
    $taskRole = aws iam get-role --role-name ecsTaskRole --query "Role.Arn" --output text
    Write-Ok "Created ecsTaskRole: $taskRole"
} else {
    Write-Ok "ecsTaskRole exists: $taskRole"
}

# ── Step 12: Register Task Definition ──
Write-Step "Step 12: Registering ECS task definition"

$projectRoot = Split-Path -Parent $PSScriptRoot
$taskDefPath = Join-Path $projectRoot "deploy\task-definition.json"
$taskDefContent = Get-Content $taskDefPath -Raw

# Replace placeholders
$taskDefContent = $taskDefContent -creplace "ACCOUNT_ID", $AccountId
$taskDefContent = $taskDefContent -creplace "REGION", $Region

$tempTaskDef = [System.IO.Path]::GetTempFileName()
$taskDefContent | Set-Content -Path $tempTaskDef

aws ecs register-task-definition --cli-input-json "file://$tempTaskDef" --region $Region | Out-Null
Remove-Item $tempTaskDef
Write-Ok "Task definition registered"

# ── Step 13: Create or Update ECS Service ──
Write-Step "Step 13: Creating ECS service '$ServiceName'"

$existingService = $null
try { $existingService = aws ecs describe-services `
    --cluster $ClusterName `
    --services $ServiceName `
    --query "services[?status=='ACTIVE'].serviceName" `
    --output text `
    --region $Region 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } } catch {}

$subnetJson = ($SubnetList | ForEach-Object { "`"$_`"" }) -join ","

if ($existingService -ne $ServiceName) {
    aws ecs create-service `
        --cluster $ClusterName `
        --service-name $ServiceName `
        --task-definition "payi-api" `
        --desired-count 1 `
        --launch-type FARGATE `
        --network-configuration "awsvpcConfiguration={subnets=[$subnetJson],securityGroups=[\`"$TaskSgId\`"],assignPublicIp=ENABLED}" `
        --load-balancers "targetGroupArn=$TgArn,containerName=payi-api,containerPort=8080" `
        --region $Region | Out-Null
    Write-Ok "ECS service created"
} else {
    aws ecs update-service `
        --cluster $ClusterName `
        --service $ServiceName `
        --task-definition "payi-api" `
        --force-new-deployment `
        --region $Region | Out-Null
    Write-Ok "ECS service updated (forced new deployment)"
}

# ── Done! ──
Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  🚀 PAYI DEPLOYED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  🌐 Public URL:  http://$AlbDns" -ForegroundColor White
Write-Host "  📊 Swagger:     http://$AlbDns/swagger" -ForegroundColor White
Write-Host "  🏥 Health:      http://$AlbDns/api/system/health" -ForegroundColor White
Write-Host ""
Write-Host "  📱 Mobile API:  http://$AlbDns/api" -ForegroundColor White
Write-Host "     Update your Flutter app's PAYI_API_BASE_URL to the above." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ⏱️  Note: It may take 2-3 minutes for the service to stabilize." -ForegroundColor Yellow
Write-Host "     Monitor: aws ecs describe-services --cluster $ClusterName --services $ServiceName --region $Region" -ForegroundColor DarkGray
Write-Host ""
