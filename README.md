# **Tennis League Manager Infrastructure**

This infrastructure manages the complete ecosystem for the **Tennis League Manager** application, implemented using **Terraform** under a decoupled modular architecture.

## **🏗️ Modular Architecture**

The project is organized into reusable modules to ensure maintenance and scalability:

* **modules/networking**: VPC configuration, private subnets, and connectivity.  
* **modules/security**: Definition of Security Groups and firewall rules.  
* **modules/identity**: Management of AWS Cognito and federation with Google Auth.  
* **modules/database**: RDS Postgres database cluster (Free Tier).  
* **modules/lambda\_api**: API Gateway and AWS Lambda functions (Quarkus/Java).  
* **modules/frontend**: Static hosting on S3 with CloudFront distribution.  
* **modules/cicd**: Complete automation via AWS CodePipeline and CodeBuild.  
* **modules/monitoring**: CloudWatch alarms integrated with SNS notifications.

## **🚀 Deployment**

### **Prerequisites**

* Terraform \>= 1.5.0  
* AWS CLI configured with sufficient permissions.  
* GitHub credentials (for CI/CD) and Google credentials (for Auth).

### **Required Variables**

To deploy, create a terraform.tfvars file in the root directory with the following variables:  
`aws_region                = "us-east-1"`  
`google_client_id          = "your-google-client-id"`  
`google_client_secret      = "your-google-client-secret"`  
`db_password               = "your-secure-password"`  
`github_username           = "your-github-username"`  
`github_backend_repo_name  = "tennis-backend"`  
`github_frontend_repo_name = "tennis-frontend"`  
`alert_email               = "admin@example.com"`

### **Main Commands**

1. **Initialize:** terraform init  
2. **Validate:** terraform validate  
3. **Plan:** terraform plan  
4. **Apply:** terraform apply

## **📋 Key Outputs**

After deployment, the project provides the following URLs and resources:

* **backend\_api\_url**: HTTP API Gateway URL to be configured as VITE\_API\_URL in the frontend.  
* **frontend\_url**: The public global URL of your deployed React application.  
* **cognito\_user\_pool\_id**: The AWS Cognito User Pool ID.

## **💡 Maintenance Notes**

This infrastructure was refactored into a modular structure. If you make changes that require moving resources, remember to use terraform state mv to prevent accidental destruction of existing resources.