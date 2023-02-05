# Change variables to meet your requirements

# AWS config
region = "us-east-2"
availability_zone = "us-east-2a"
public_key_name = "id_teleport"
// custom-tags = {"tag_name": "tag_value"}

# Teleport AMI name
# https://github.com/gravitational/teleport/blob/master/examples/aws/terraform/starter-cluster/README.md#steps
ami_name = "gravitational-teleport-ami-oss-11.0.1"

# Teleport cluster name (max 20 characters)
cluster_name = "btv_prod_teleport"

# Teleport S3 bucket
s3_bucket_name = "tv_prod_teleport-s3"

# Teleport URL & root domain name
route53_zone = "btv.org"
route53_domain = "teleport.btv.org"
add_wildcard_route53_record = true

# Let's Encrypt certificate registration
email = "tyler.lindberg@zb-c.tech"
use_letsencrypt = true
use_acm = false
