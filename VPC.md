# **Day 4 – AWS VPC Fundamentals (LocalStack & AWS CLI)**

### **Goal:**

Understand the basics of **Virtual Private Cloud (VPC)**, subnets, route tables, and Internet Gateways, and create a simple VPC network locally using LocalStack.

---

## **Step 1: Overview of VPC Components**

Before creating resources, understand these components:

| Component                  | Purpose                                                    |
| -------------------------- | ---------------------------------------------------------- |
| **VPC**                    | Logical isolated network in AWS for your resources.        |
| **Subnet**                 | Segment of VPC IP address range. Can be public or private. |
| **Route Table**            | Defines how traffic flows in/out of subnets.               |
| **Internet Gateway (IGW)** | Enables communication between VPC and the internet.        |
| **Security Group**         | Virtual firewall controlling inbound/outbound traffic.     |

---

## **Step 2: Create a VPC**

```bash
aws --endpoint-url=http://localhost:4566 ec2 create-vpc --cidr-block 10.0.0.0/16 \
--tag-specification 'ResourceType=vpc,Tags=[{Key=Name,Value=MyVPC}]' --profile localstack
```

**Explanation:**

- `10.0.0.0/16` defines the IP address range.
- Tag `Name=MyVPC` helps identify the VPC.

**Output**:

```bash
aws --endpoint-url=http://localhost:4566 ec2 create-vpc --cidr-block 10.0.0.0/16 \
--tag-specification 'ResourceType=vpc,Tags=[{Key=Name,Value=MyVPC}]' --profile localstack
{
    "Vpc": {
        "OwnerId": "000000000000",
        "InstanceTenancy": "default",
        "Ipv6CidrBlockAssociationSet": [],
        "CidrBlockAssociationSet": [
            {
                "AssociationId": "vpc-cidr-assoc-4caa2e831744a2c38",
                "CidrBlock": "10.0.0.0/16",
                "CidrBlockState": {
                    "State": "associated"
                }
            }
        ],
        "IsDefault": false,
        "Tags": [
            {
                "Key": "Name",
                "Value": "MyVPC"
            }
        ],
        "VpcId": "vpc-d0a649179bc66dd53",
        "State": "available",
        "CidrBlock": "10.0.0.0/16",
        "DhcpOptionsId": "default"
    }
}
```

## **Step 3: Create a Subnet**

```bash
aws --endpoint-url=http://localhost:4566 ec2 create-subnet --vpc-id <VPC_ID> --cidr-block 10.0.1.0/24 \
--tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnet}]' --profile localstack
```

- Replace `<VPC_ID>` with the VPC ID from Step 2 - vpc-d0a649179bc66dd53.
- `10.0.1.0/24` is the subnet IP range.

example:

```bash
aws --endpoint-url=http://localhost:4566 ec2 create-subnet --vpc-id vpc-d0a649179bc66dd53 --cidr-block 10.0.1.0/24 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnet}]' --profile localstack

```

Output:

```json
{
  "Subnet": {
    "AvailabilityZoneId": "use1-az6",
    "OwnerId": "000000000000",
    "AssignIpv6AddressOnCreation": false,
    "Ipv6CidrBlockAssociationSet": [],
    "Tags": [
      {
        "Key": "Name",
        "Value": "PublicSubnet"
      }
    ],
    "SubnetArn": "arn:aws:ec2:us-east-1:000000000000:subnet/subnet-8e1cfb7ee68778451",
    "Ipv6Native": false,
    "SubnetId": "subnet-8e1cfb7ee68778451",
    "State": "available",
    "VpcId": "vpc-d0a649179bc66dd53",
    "CidrBlock": "10.0.1.0/24",
    "AvailableIpAddressCount": 251,
    "AvailabilityZone": "us-east-1a",
    "DefaultForAz": false,
    "MapPublicIpOnLaunch": false
  }
}
```

---

## **Step 4: Create an Internet Gateway (IGW)**

```bash
aws --endpoint-url=http://localhost:4566 ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=MyIGW}]' --profile localstack
```

output:

```bash
{
    "InternetGateway": {
        "Attachments": [],
        "InternetGatewayId": "igw-79f3c775b3c6e997f",
        "OwnerId": "000000000000",
        "Tags": [
            {
                "Key": "Name",
                "Value": "MyIGW"
            }
        ]
    }
}
```

**Attach it to your VPC:**

```bash
aws --endpoint-url=http://localhost:4566 ec2 attach-internet-gateway \
  --vpc-id <VPC_ID> \
  --internet-gateway-id <IGW_ID> \
  --profile localstack
```

One Liner Example:

```bash
aws --endpoint-url=http://localhost:4566 ec2 attach-internet-gateway --vpc-id vpc-d0a649179bc66dd53 --internet-gateway-id igw-79f3c775b3c6e997f --profile localstack
```

---

## **Step 5: Create a Route Table**

```bash
aws --endpoint-url=http://localhost:4566 ec2 create-route-table \
  --vpc-id <VPC_ID> \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PublicRouteTable}]' \
  --profile localstack
```

One liner:

```bash
aws --endpoint-url=http://localhost:4566 ec2 create-route-table --vpc-id vpc-d0a649179bc66dd53 --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PublicRouteTable}]' --profile localstack
```

```json
{
  "RouteTable": {
    "Associations": [],
    "RouteTableId": "rtb-18ca9b56c6b0b99cb",
    "Routes": [
      {
        "DestinationCidrBlock": "10.0.0.0/16",
        "GatewayId": "local",
        "State": "active"
      }
    ],
    "Tags": [
      {
        "Key": "Name",
        "Value": "PublicRouteTable"
      }
    ],
    "VpcId": "vpc-d0a649179bc66dd53",
    "OwnerId": "000000000000"
  }
}
```

Create a route to IGW:

```bash
aws --endpoint-url=http://localhost:4566 ec2 create-route \
  --route-table-id <ROUTE_TABLE_ID> \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id <IGW_ID> \
  --profile localstack
```

One liner

```bash
aws --endpoint-url=http://localhost:4566 ec2 create-route --route-table-id rtb-18ca9b56c6b0b99cb --destination-cidr-block 0.0.0.0/0 --gateway-id igw-79f3c775b3c6e997f --profile localstack
```

```json
{
  "Return": true
}
```

Associate route table with subnet:

```bash
aws --endpoint-url=http://localhost:4566 ec2 associate-route-table \
  --subnet-id <SUBNET_ID> \
  --route-table-id <ROUTE_TABLE_ID> \
  --profile localstack
```

One liner:

```bash
aws --endpoint-url=http://localhost:4566 ec2 associate-route-table --subnet-id subnet-8e1cfb7ee68778451 --route-table-id rtb-18ca9b56c6b0b99cb --profile localstack
```

output:

```json
{
  "AssociationId": "rtbassoc-0c497cd2bf7eeb6fb"
}
```

## **Step 6: Verify the VPC Setup**

```bash
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs --profile localstack
aws --endpoint-url=http://localhost:4566 ec2 describe-subnets --profile localstack
aws --endpoint-url=http://localhost:4566 ec2 describe-route-tables --profile localstack
```

**Outcome:**

**functional VPC with a public subnet and internet access** (simulated in LocalStack).

---

## **Step 7: Learning Outcomes**

- Learned how to create a **VPC, subnet, IGW, and route table**.
- Understood the basic **network architecture** for AWS workloads.
- Practiced using **AWS CLI with LocalStack** for local testing.
