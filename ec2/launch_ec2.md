### Prerequisites for Emulating an EC2 Instance with LocalStack

To emulate an Amazon Elastic Compute Cloud (EC2) instance on a local machine using LocalStack, ensure the following requirements are met:

- A Linux host operating system is required, as network access to emulated instances is not supported on macOS.
- Docker Engine must be installed and running, as LocalStack uses Docker containers to emulate EC2 instances.
- LocalStack Pro edition (or equivalent, such as the Hobby Plan) is necessary for full EC2 emulation capabilities. The Community edition provides only basic mock operations.
- Obtain a LocalStack authentication token by signing up for the Pro or Hobby Plan via the LocalStack website.
- Install the AWS Command Line Interface (CLI) if not already present, using the official AWS installation guide.
- Install the LocalStack CLI via Python's package manager: `pip install localstack`.
- Basic familiarity with command-line tools and AWS CLI syntax is assumed.

### Step-by-Step Instructions to Run an EC2 Instance Locally

1. **Set Up the LocalStack Environment**  
   Export the LocalStack authentication token as an environment variable to activate the Pro features:

   ```
   export LOCALSTACK_AUTH_TOKEN=your-auth-token-here
   ```

   Start the LocalStack container:

   ```
   localstack start
   ```

   Verify the setup by querying the LocalStack information endpoint:

   ```
   curl http://localhost:4566/_localstack/info | jq
   ```

   Confirm that the output indicates `"edition": "pro"` and `"is_license_activated": true`.

2. **Create an EC2 Key Pair**  
   Generate a new key pair for SSH access to the emulated instance and save the private key material to a file:

   ```
   awslocal ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text | tee key.pem
   ```

   Secure the private key file by setting appropriate permissions:

   ```
   chmod 400 key.pem
   ```

   Alternatively, if using an existing SSH public key (e.g., from `~/.ssh/id_rsa.pub`), import it:

   ```
   awslocal ec2 import-key-pair --key-name my-key --public-key-material file://~/.ssh/id_rsa.pub
   ```

3. **Configure the Default Security Group**  
   Retrieve the ID of the default security group:

   ```
   sg_id=$(awslocal ec2 describe-security-groups | jq -r '.SecurityGroups[0].GroupId')
   ```

   Authorize inbound traffic on a specified port (e.g., port 8000 for a web server example):

   ```
   awslocal ec2 authorize-security-group-ingress --group-id default --protocol tcp --port 8000 --cidr 0.0.0.0/0
   ```

   Note that LocalStack currently supports only the default security group and limits ingress rules to up to 32 ports to avoid host port exhaustion.

4. **Prepare a User Data Script**  
   Create a shell script file named `user_script.sh` to execute upon instance launch. This example installs dependencies and starts a simple Python web server:

   ```
   #!/bin/bash -xeu
   apt update
   apt install python3 -y
   python3 -m http.server 8000
   ```

   Save the file and ensure it is executable if needed.

5. **Launch the EC2 Instance**  
   Run the instance using the prepared key pair, security group, and user data script. Use a supported Amazon Machine Image (AMI) ID, such as `ami-ff0fea8310f3` for Ubuntu 20.04:

   ```
   awslocal ec2 run-instances --image-id ami-ff0fea8310f3 --count 1 --instance-type t3.nano --key-name my-key --security-group-ids $sg_id --user-data file://./user_script.sh
   ```

   Note: The instance type (e.g., `t3.nano`) has no functional impact in emulation, as LocalStack uses a fixed Docker image. For Amazon Linux, use AMI ID `ami-024f768332f0` and adjust the script to use `yum` instead of `apt`.

6. **Verify the Instance Status**  
   Confirm the emulated instance is running by listing Docker containers:

   ```
   docker ps
   ```

   The container name will resemble `ec2-instance-i-0b0f1f2f3f4f5f6f7`.  
   Retrieve the instance ID:

   ```
   instance_id=$(awslocal ec2 describe-instances | jq -r '.Reservations[0].Instances[0].InstanceId')
   ```

   Describe the instance to obtain details, including IP addresses:

   ```
   awslocal ec2 describe-instances --instance-ids $instance_id | jq
   ```

   The output will include a private IP (e.g., `10.0.2.15`) and public IP (e.g., `172.17.0.3`).

7. **Access the Instance via SSH**  
   Establish an SSH connection using the private key and the instance's public IP address (default username is `ubuntu` for Ubuntu-based AMIs):

   ```
   ssh -i key.pem ubuntu@<public-ip-address>
   ```

   Replace `<public-ip-address>` with the value from the previous step.

8. **Test the Running Application**  
   If the user data script starts a service (e.g., a web server on port 8000), LocalStack maps the container's port to a high port on the host (typically in the 46000-47000 range). Inspect the Docker container to find the mapped port:

   ```
   docker inspect <container-id> | jq '.[0].NetworkSettings.Ports'
   ```

   Access the service via the host's mapped port, for example:

   ```
   curl http://localhost:<mapped-port>/
   ```

9. **Terminate the Instance**  
   When testing is complete, terminate the instance to stop the emulation:
   ```
   awslocal ec2 terminate-instances --instance-ids $instance_id
   ```

These steps enable local emulation of an EC2 instance without interacting with actual AWS resources, facilitating cost-effective development and testing. For advanced configurations, consult the official LocalStack documentation.
