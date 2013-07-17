#!/bin/bash
#
# Starts a group of autoscaling EC2 instances
# 
# copyright Chris Kirkland 2012 mrkirkland.com
# permission granted to use modify, no warranty, use as is, don't blame me if your virtual server catches fire and amazon bill is 1 million USD etc
#
# USAGE
# 0) you need installed the AWS command line tools http://aws.amazon.com/developertools/2535 docs http://docs.aws.amazon.com/AutoScaling/latest/DeveloperGuide/UsingTheCommandLineTools.html
#
# 1) edit config below
#  * set your AMI and AVAILABILTY_ZONES
#  * tweak INSTANCE_TYPE, MAX + MIN INSTANCES depending on your estimated needs (NB number of MIN_INSTANCES will constantly be running)
#  * for finer tuning experiment with the COOLDOWN and CPU values  
#  * if you are going to run multiple autoscaling groups then you might need to edit the BASE_NAME for each time you run the script (though it auto creates a name based on the date and hour)
# 
#
# 2) execute with 
#  > aws-start-as-group.sh
#
# 3) terminate all resources with 
#  > aws-shut-down-as-group.sh $BASE_NAME
#  NB $BASE_NAME is set in the config below when you run this script and echoed at the end, it's a prefix and todays date
#-----------------------------------------------------------------------------#


shopt -s -o nounset

declare -rx SCRIPT=${0##*/}

# variables
DATE=$(date +%Y-%m-%d-%H);

#-----------------------------------------------------------------------------#
# ----- AWS EDITABLE CONFIG ----- #
#launch config
AMI=ami-97c46cfe
INSTANCE_TYPE=t1.micro

#scaling group
MIN_INSTANCES=3
MAX_INSTANCES=15
AVAILABILTY_ZONES="us-east-1a"

#policy
UP_COOLDOWN=600
DOWN_COOLDOWN=600

#alarm
HIGH_CPU=80
LOW_CPU=40
PERIOD=300



# ----- AWS NAMING NORMALLY NO NEEd TO EDIT ----- #
BASE_NAME=ASG-$DATE

#launch config
MyLB=ASG-LB
MyLC=$BASE_NAME-LaunchConfig

#scaling group
MyAutoScalingGroup=$BASE_NAME-ScalingGroup

#policy
MyScaleUpPolicy=$BASE_NAME-ScaleUpPolicy
MyScaleDownPolicy=$BASE_NAME-ScaleDownPolicy

#alarm
MyHighCPUAlarm=$BASE_NAME-HighCPUAlarm
MyLowCPUAlarm=$BASE_NAME-LowCPUAlarm
#-----------------------------------------------------------------------------#



#1 create launch config
echo "# --- 1 create launch config --- #"
out=$(as-create-launch-config $MyLC -f --image-id $AMI --instance-type $INSTANCE_TYPE)
if [ $? = 1 ] ; then
	printf "Failed to create launch group $MyLC";
	exit 192;
fi
echo "$MyLC";

#2 create scaling group
echo "# --- 2 create scaling group --- #"
out=$(as-create-auto-scaling-group $MyAutoScalingGroup -f --launch-configuration $MyLC --availability-zones $AVAILABILTY_ZONES --min-size $MIN_INSTANCES --max-size $MAX_INSTANCES --load-balancers $MyLB)
if [ $? = 1 ] ; then
	printf "Failed to create scaling group $MyAutoScalingGroup";
	exit 192;
fi
echo "$MyAutoScalingGroup";


#3 create up policy
echo "# --- 3 create up policy ---#"
out=$(as-put-scaling-policy $MyScaleUpPolicy -f --auto-scaling-group $MyAutoScalingGroup  --adjustment=1 --type ChangeInCapacity  --cooldown $UP_COOLDOWN)
if [ $? = 1 ] ; then
	printf "Failed to create Up Policy  $MyScaleUpPolicy";
	exit 192;
fi
echo "$MyScaleUpPolicy - $out";
UP_ARN=$out;

#4 alarms
echo "# --- 4 alarms --- #"
out=$(mon-put-metric-alarm $MyHighCPUAlarm -f  --comparison-operator  GreaterThanThreshold  --evaluation-periods  1 --metric-name  CPUUtilization  --namespace  "AWS/EC2"  --period  $PERIOD  --statistic Average --threshold  $HIGH_CPU --alarm-actions $UP_ARN --dimensions "AutoScalingGroupName=$MyAutoScalingGroup")
if [ $? = 1 ] ; then
	printf "Failed to create alarm $MyHighCPUAlarm";
	exit 192;
fi
echo "$MyHighCPUAlarm";


#5 create down policy
echo "# --- 5 create down policy --- #"
out=$(as-put-scaling-policy $MyScaleDownPolicy -f --auto-scaling-group $MyAutoScalingGroup  --adjustment=-1 --type ChangeInCapacity  --cooldown $DOWN_COOLDOWN)
if [ $? = 1 ] ; then
	printf "Failed to create Down Policy  $MyScaleDownPolicy";
	exit 192;
fi
echo "$MyScaleDownPolicy - $out";
DOWN_ARN=$out;


#6 alarms
echo "# --- 6 alarms --- #"
out=$(mon-put-metric-alarm $MyLowCPUAlarm -f  --comparison-operator  LessThanThreshold --evaluation-periods  1 --metric-name  CPUUtilization --namespace  "AWS/EC2"  --period  $PERIOD  --statistic Average --threshold  $LOW_CPU  --alarm-actions $DOWN_ARN --dimensions "AutoScalingGroupName=$MyAutoScalingGroup")
if [ $? = 1 ] ; then
        printf "Failed to create alarm $MyLowCPUAlarm";
        exit 192;
fi
echo "$MyLowCPUAlarm";


echo "# ---------- All commands exectued -------- #"
sleep 5
as-describe-auto-scaling-groups $MyAutoScalingGroup --headers

echo "# ---------- BASE_NAME: $BASE_NAME -------- #"

