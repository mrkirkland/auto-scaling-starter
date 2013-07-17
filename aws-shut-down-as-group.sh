#!/bin/bash
#
# Stops a group of autoscaling EC2 instances
# 
# copyright Chris Kirkland 2012 mrkirkland.com
# permission granted to use modify, no warranty, use as is, don't blame me if your virtual server catches fire and amazon bill is 1 million USD etc
#
# USAGE
# 0) you need installed the AWS command line tools http://aws.amazon.com/developertools/2535

# 1) terminate all resources with 
#  > aws-shut-down-as-group.sh $BASE_NAME
#  NB $BASE_NAME is out put from the aws-start-as-group.sh script. You can find this out with as-describe-auto-scaling-groups 
#
# 2) once the script has complete, run the commands it outputs at the end manually to delete the group, config, alarms and load balancer
#-----------------------------------------------------------------------------#



shopt -s -o nounset

declare -rx SCRIPT=${0##*/}

# ----- AWS CONFIG ----- #
BASE_NAME=$1

#launch config
MyLB=phpthumb-LB
MyLC=$BASE_NAME-LaunchConfig

#scaling group
MyAutoScalingGroup=$BASE_NAME-ScalingGroup

#policy
MyScaleUpPolicy=$BASE_NAME-ScaleUpPolicy
MyScaleDownPolicy=$BASE_NAME-ScaleDownPolicy

#alarm
MyHighCPUAlarm=$BASE_NAME-HighCPUAlarm
MyLowCPUAlarm=$BASE_NAME-LowCPUAlarm

echo # --- 1 set to zero size --- #"
as-update-auto-scaling-group $MyAutoScalingGroup --min-size 0 --max-size 0

echo "now wait for termination and execute the following commands:"
echo
echo "as-delete-auto-scaling-group $MyAutoScalingGroup -f"
echo "as-delete-launch-config $MyLC -f"
echo "mon-delete-alarms $MyHighCPUAlarm $MyLowCPUAlarm -f"
echo "# and optionally:"
echo "elb-delete-lb $MyLB"


for i in 1 2 3 4 5 6 7 8 9;
do
 as-describe-auto-scaling-groups $MyAutoScalingGroup --headers
 sleep 5;
done

