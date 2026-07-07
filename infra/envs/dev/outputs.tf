output "alb_dns_name" {
  description = "Public URL of the application (http://<this>)."
  value       = module.ecs.alb_dns_name
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "rds_endpoint" {
  description = "Private RDS endpoint (reachable only from ECS)."
  value       = module.rds.db_endpoint
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}
