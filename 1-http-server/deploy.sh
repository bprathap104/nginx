#!/bin/bash
##remove previous dist if exists
rm -rf dist

##move other required files to dist
mkdir -p dist/1-http-server
cp -r shScripts/* dist/
cp appspec.yml ./dist/
cp -r netflix-website-project/ ./dist/1-http-server/
cd ./dist
ls -ltr

## Zip evertyhing within the dist folder, excluding any hidden macOs files (-X)
zip -r -X 1-http-server-dist.zip *

##upload to s3. AWS CLI must be installed
aws s3 cp 1-http-server-dist.zip s3://my-deployment-bucket-1234567890/

aws deploy create-deployment --application-name 1-http-server --deployment-group-name 1-http-server-DGroup1 --description "$1" --s3-location bucket=my-deployment-bucket-1234567890,bundleType=zip,key=1-http-server-dist.zip --ignore-application-stop-failures
