// tf_addressbook outputs:
output "addressbook_elb_name" {
  value = "${aws_elb.addressbook_web_elb.name}"
}
output "addressbook_dns_name" {
  value = "${aws_elb.addressbook_web_elb.dns_name}"
}
