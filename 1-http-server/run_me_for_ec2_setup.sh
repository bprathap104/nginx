echo -n Enter AWS Access Key: 
read -s access_key
echo -n Enter AWS SecretAccess Key: 
read -s secret_key

export AWS_ACCESS_KEY_ID=$access_key
export AWS_SECRET_ACCESS_KEY=$secret_key
export AWS_DEFAULT_REGION=us-east-1

## Create an EC2 instance profile
cat << 'EOF' > policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role --role-name ec2_role_new --assume-role-policy-document file://policy.json --output text
rm -f policy.json
aws iam attach-role-policy --role-name ec2_role_new --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore  --output text
aws iam attach-role-policy --role-name ec2_role_new --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess  --output text
aws iam attach-role-policy --role-name ec2_role_new --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess  --output text

aws iam create-instance-profile --instance-profile-name ec2_role_instance_profile  --output text
aws iam add-role-to-instance-profile --role-name ec2_role_new --instance-profile-name ec2_role_instance_profile  --output text

latest_ami=`aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region us-east-1  --query "Parameters[*].Value" --output text`
echo $latest_ami

## Fetchh default VPC Id
default_vpc=`aws ec2 describe-vpcs --query "Vpcs[*].VpcId" --output text`
echo $default_vpc

## Fetch default Security Group from default VPC
default_sg_id=`aws ec2 describe-security-groups --filters Name=vpc-id,Values=$default_vpc --query "SecurityGroups[*].GroupId" --output text`
echo $default_sg_id

## Authorize EC2 SG Ingress
aws ec2 authorize-security-group-ingress --group-id $default_sg_id --protocol tcp --port 80 --cidr 0.0.0.0/0

## Fetch one public subnet from default VPC
default_subnet=`aws ec2 describe-subnets --filters Name=availability-zone,Values=us-east-1a Name=vpc-id,Values=$default_vpc --query "Subnets[*].SubnetId" --output text`
echo $default_subnet

sleep 5

## Launch one EC2 with user-data and above values
instance_id=`aws ec2 run-instances --image-id $latest_ami --count 1 --instance-type t2.micro  --security-group-ids $default_sg_id --subnet-id $default_subnet --user-data file://setting-up-code-deploy-agent.sh --query "Instances[*].InstanceId" --output text \
--tag-specifications 'ResourceType=instance,Tags=[{Key=PROJECT,Value=1-http-server}]' --iam-instance-profile Name=ec2_role_instance_profile`
echo $instance_id
