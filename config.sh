#!/usr/bin/env bash
# Script for generating nextflow.config file

# ex. nextflow.config
# cloud {
#     imageId = 'ami-f34507e5'
#     instanceType = 'm4.xlarge'
#     userName = 'your_username'
#     keyName = 'your_keyname'
# }

RED='\033[0;31m'
Green='\033[0;32m' 
NC='\033[0m'


echo -n "Enter keyName [*REQUIRED*]: "
read keyname
if [ -z ${keyname} ];then
	printf "${RED}valid ${RED}keyName ${RED}required!${NC}\n"
	exit 1
fi

username="ec2-user"

echo -n "Enter instance type [default = m4.xlarge]: "
read instance
if [ -z ${instance} ];then
	instance="m4.xlarge"
fi

echo -n "Enter subnet ID: "
read subnet

echo -n "Enter security group: "
read sggroup

#echo -n "Enter EFS ID: "
#read efsid
efs_token=$(date | awk 'BEGIN{OFS="_"} {print $2, $3, $6}') #create unique efs token based on current date.
read -p "Automatically create EFS Filesystem? [y/n] " efs_prompt
if [ $efs_prompt == "y" ]
then 
	efs_id=$(aws efs create-file-system --creation-token $efs_token"_nextflowFS" --region us-east-1 --profile default | grep FileSystemId | awk -F "\"" '{print $4}') #Create Elastic File System
	aws efs create-tags --file-system-id $efs_id --tags Key=Name,Value=$efs_token"_nextflowFS" --region us-east-1 --profile default #Tag elastic filesystem
	sleep 10
	aws efs create-mount-target --file-system-id $efs_id --subnet-id subnet-052a174d --security-group sg-9d9253e1 --region us-east-1 --profile default #Create mount target on Elastic File System
        echo "EFS Filesystem Creation Completed! "
elif [ $efs_prompt == "n" ]
then 
	read -p "Enter EFS ID:  " efs_id
fi

echo "cloud{" > nextflow.config
echo "	imageId = 'ami-d1f9a6aa'" >> nextflow.config
echo "	instanceType = '${instance}'" >> nextflow.config
echo "	userName = '${username}'" >> nextflow.config
echo "	keyName = '${keyname}'" >> nextflow.config

if [ ! -z ${sggroup} ];then
	echo "	securityGroup = '${sggroup}'" >> nextflow.config
fi

if [ ! -z ${subnet} ];then
	echo "	subnetId = '${subnet}'" >> nextflow.config
fi

if [ ! -z ${efs_id} ];then
	echo "	sharedStorageId = '${efs_id}'" >> nextflow.config
else
	printf "${RED}EFS ID is required! ${NC}\n"
fi

echo "}" >> nextflow.config
echo ""
echo "-- nextflow.config --"
cat nextflow.config
echo ""

nextflow=`which nextfldw`
if [ -z ${nextflow} ];then
	echo -n "Would you like to download nextflow? [y/n]"
	read nextdl
	if [ "${nextdl}" == "y" ] || [ "${nextdl}" == "Y" ] || [ "${nextdl}" == "yes" ];then
		curl -fsSL get.nextflow.io | bash
		working=`pwd`
		echo "add $working to your PATH environment variable"
		echo ""
		printf "${Green}*************************************************** ${NC}\n"
		printf "${Green}* You can now create a GFE cluster with nextflow! * ${NC}\n"
		printf "${Green}* ./nextflow cloud create gfe-cluster -c          * ${NC}\n"
		printf "${Green}*************************************************** ${NC}\n"
	fi
else
	printf "${Green}*************************************************** ${NC}\n"
	printf "${Green}* You can now create a GFE cluster with nextflow! * ${NC}\n"
	printf "${Green}* ./nextflow cloud create gfe-cluster -c          * ${NC}\n"
	printf "${Green}*************************************************** ${NC}\n"
fi







