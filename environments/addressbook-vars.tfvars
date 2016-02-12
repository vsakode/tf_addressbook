//aws provider variables
aws_access_key = "********************"
aws_secret_key = "********************"
aws_region = "us-east-1"
mytag = "production"
service = "addressbook"

//Subnets
subnet_az1 = "*******************"
subnet_az2 = "*******************"
az1 = "us-east-1b"
az2 = "us-east-1c"

//SG module inputs
vpc_id = "*******************"
security_group_name = "addressbook"
source_cidr_block = "*******************"

//ELB module inputs
elb_name = "addressbook"
backend_port = "8080"
backend_protocol = "http"
health_check_target = "HTTP:80/"
elb_is_internal = "false"

//ASG module inputs
ami_id = "ami-0011546a"
instance_type = "m3.large"
health_check_type = "EC2"
minimum_number_of_instances = 2
asg_name = "addressbook"
lc_name = "addressbook"
key_name = "opsome"
user_data = "/Users/vsakode/vsakode-github/tf_addressbook/bootstrap_addressbook.sh"
asg_number_of_instances = 2
asg_minimum_number_of_instances = 2
health_check_grace_period = 300
