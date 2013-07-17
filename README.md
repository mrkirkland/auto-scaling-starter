auto-scaling-starter
====================

Two scripts to Start and stop a group of autoscaling EC2 instances
------------------------------------------------------------------

Copyright Chris Kirkland 2012 mrkirkland.com
Permission granted to use modify, no warranty, use as is, don't blame me if your virtual server catches fire and amazon bill is 1 million USD etc


INSTALLATION
0) you need installed the AWS command line tools http://aws.amazon.com/developertools/2535 docs http://docs.aws.amazon.com/AutoScaling/latest/DeveloperGuide/UsingTheCommandLineTools.html

1) chmod 755 the scripts
> chmod 755 aws-start-as-group.sh
> chmod 755 aws-shut-down-as-group.sh

2) edit the config at the top of each script


USAGE
1) edit config below
		* set your AMI and AVAILABILTY_ZONES
* tweak INSTANCE_TYPE, MAX + MIN INSTANCES depending on your estimated needs (NB number of MIN_INSTANCES will constantly be running)
		* for finer tuning experiment with the COOLDOWN and CPU values  
* if you are going to run multiple autoscaling groups then you might need to edit the BASE_NAME for each time you run the script (though it auto creates a name based on the date and hour)


2) execute with 
> aws-start-as-group.sh

3) terminate all resources with 
> aws-shut-down-as-group.sh $BASE_NAME
NB $BASE_NAME is set in the config and when you run this script it is echoed at the end, it's a prefix and todays date




