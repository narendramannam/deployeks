output "acm_certificate_arn" {
    value = module.acm.acm_certificate_arn
}

output "acm_certificate_fqdn" {
    value = module.acm.distinct_domain_names[0]
}