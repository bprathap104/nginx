cat << 'EOF' > trust_policy.json
{
    "Version": "2012-10-17",     
    "Statement": [ 
        {
            "Sid": "",      
            "Effect": "Allow",         
            "Principal": {               
                "Service": [                
                               "codedeploy.amazonaws.com"      
                           ]
            },
            "Action": "sts:AssumeRole"
        }     
    ]
}
EOF


aws s3api create-bucket --bucket my-deployment-bucket-1234567890 --region us-east-1 --output text

# account_id=`aws sts get-caller-identity --query Account --output text`

role_arn=`aws iam create-role --role-name CodeDeployServiceRole --assume-role-policy-document file://trust_policy.json --output text --query Role.Arn`

rm -f trust_policy.json

aws iam attach-role-policy --role-name CodeDeployServiceRole --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole --output text
aws iam attach-role-policy --role-name CodeDeployServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --output text


aws deploy create-application --application-name 1-http-server --output text

aws deploy create-deployment-group --application-name 1-http-server --deployment-group-name 1-http-server-DGroup1 --ec2-tag-filters Key=PROJECT,Value=1-http-server,Type=KEY_AND_VALUE --service-role-arn $role_arn --output text

# aws deploy create-deployment --application-name 1-http-server --deployment-config-name CodeDeployDefault.AllAtOnce --deployment-group-name 1-http-server-DGroup1 --description "$1" --s3-location bucket=my-deployment-bucket-1234567890,bundleType=zip,key=1-http-server-dist.zip --ignore-application-stop-failures

### aws deploy get-deployment --deployment-id d-A1B2C3123
