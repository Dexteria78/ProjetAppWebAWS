#!/bin/bash
# Script de test de charge pour Phase 6
# Teste le scaling automatique et la haute disponibilité

set -e

echo "🧪 Phase 6 - Load Testing & Auto-Scaling Validation"
echo "===================================================="
echo ""

# Check if ALB URL is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <ALB_DNS_NAME>"
    echo ""
    echo "Exemple:"
    echo "  $0 student-records-alb-phase6-123.us-east-1.elb.amazonaws.com"
    echo ""
    echo "Ou avec Terraform:"
    echo "  $0 \$(terraform output -raw alb_dns_name)"
    exit 1
fi

ALB_URL="http://$1"
ASG_NAME="student-records-asg-phase6"

echo "📍 Target URL: $ALB_URL"
echo "📊 ASG Name: $ASG_NAME"
echo ""

# Check if Apache Bench is installed
if ! command -v ab &> /dev/null; then
    echo "❌ Apache Bench (ab) not found"
    echo ""
    echo "Installing..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y apache2-utils
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "On macOS, ab should be pre-installed"
    fi
fi

# Function to get current ASG size
get_asg_size() {
    aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names $ASG_NAME \
        --query 'AutoScalingGroups[0].DesiredCapacity' \
        --output text 2>/dev/null || echo "0"
}

# Function to get instance count
get_instance_count() {
    aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names $ASG_NAME \
        --query 'AutoScalingGroups[0].Instances | length(@)' \
        --output text 2>/dev/null || echo "0"
}

# Function to check if app is responding
health_check() {
    response=$(curl -s -o /dev/null -w "%{http_code}" $ALB_URL/students)
    if [ "$response" == "200" ]; then
        echo "✅ Health check passed (HTTP $response)"
        return 0
    else
        echo "❌ Health check failed (HTTP $response)"
        return 1
    fi
}

echo "Step 1: Initial Health Check"
echo "=============================="
health_check || exit 1
echo ""

echo "Step 2: Baseline State"
echo "======================"
INITIAL_SIZE=$(get_asg_size)
INITIAL_INSTANCES=$(get_instance_count)
echo "Current ASG desired capacity: $INITIAL_SIZE"
echo "Current instance count: $INITIAL_INSTANCES"
echo ""

echo "Step 3: Light Load Test (Baseline)"
echo "===================================="
echo "Running: 100 requests, 10 concurrent"
ab -n 100 -c 10 -q $ALB_URL/students | grep -E "Requests per second|Time per request|Failed requests"
echo ""
sleep 5

echo "Step 4: Medium Load Test"
echo "========================="
echo "Running: 500 requests, 25 concurrent"
ab -n 500 -c 25 -q $ALB_URL/students | grep -E "Requests per second|Time per request|Failed requests"
echo ""
sleep 5

echo "Step 5: Heavy Load Test (Trigger Scale-Up)"
echo "==========================================="
echo "Running: 2000 requests, 50 concurrent"
echo "This should trigger CPU scaling..."
ab -n 2000 -c 50 $ALB_URL/students | grep -E "Requests per second|Time per request|Failed requests"
echo ""

echo "Step 6: Sustained Load (3 rounds)"
echo "=================================="
for i in {1..3}; do
    echo "Round $i/3: 1000 requests, 50 concurrent"
    ab -n 1000 -c 50 -q $ALB_URL/students | grep -E "Requests per second|Failed requests"
    
    CURRENT_SIZE=$(get_asg_size)
    echo "  Current ASG size: $CURRENT_SIZE"
    
    if [ "$CURRENT_SIZE" -gt "$INITIAL_SIZE" ]; then
        echo "  🎉 Scale-up detected! ($INITIAL_SIZE → $CURRENT_SIZE)"
    fi
    
    sleep 15
done
echo ""

echo "Step 7: Wait for Scaling Activity"
echo "==================================="
echo "Waiting 2 minutes for scaling decisions..."
sleep 120

FINAL_SIZE=$(get_asg_size)
FINAL_INSTANCES=$(get_instance_count)

echo ""
echo "📊 Final State:"
echo "  Initial capacity: $INITIAL_SIZE"
echo "  Final capacity: $FINAL_SIZE"
echo "  Instances: $FINAL_INSTANCES"

if [ "$FINAL_SIZE" -gt "$INITIAL_SIZE" ]; then
    echo ""
    echo "✅ AUTO-SCALING VERIFIED!"
    echo "   ASG scaled from $INITIAL_SIZE to $FINAL_SIZE instances"
else
    echo ""
    echo "⚠️  No scaling detected yet"
    echo "   Check CloudWatch metrics - scaling may take 3-5 minutes"
fi

echo ""
echo "Step 8: Scaling Activity History"
echo "=================================="
echo "Recent scaling activities:"
aws autoscaling describe-scaling-activities \
    --auto-scaling-group-name $ASG_NAME \
    --max-records 5 \
    --query 'Activities[*].[StartTime,StatusCode,Description]' \
    --output table

echo ""
echo "Step 9: CloudWatch Metrics"
echo "=========================="
echo "Average CPU over last 10 minutes:"
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=AutoScalingGroupName,Value=$ASG_NAME \
    --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average \
    --query 'Datapoints[*].[Timestamp,Average]' \
    --output table

echo ""
echo "🎯 Load Test Complete!"
echo ""
echo "Next steps:"
echo "  1. Monitor CloudWatch Dashboard for detailed metrics"
echo "  2. Wait 10 minutes to see scale-down (if CPU drops below 30%)"
echo "  3. Check target group health in ALB console"
echo ""
echo "Commands:"
echo "  Dashboard: terraform output cloudwatch_dashboard_url"
echo "  Watch ASG: watch -n 5 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query \"AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize]\"'"
