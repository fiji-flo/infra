provider "aws" {
  region = "${var.region}"
}

module "db_stage" {
  source         = "./modules/db"
  environment    = "stage"
  vpc_id         = "${data.terraform_remote_state.vpc-us-west-2.vpc_id}"
  identifier     = "developer-portal"
  instance_class = "db.t3.medium"
  db_name        = "developer_portal"
  db_user        = "${lookup(var.rds, "user.stage")}"
  db_password    = "${lookup(var.rds, "password.stage")}"
}

module "bucket_stage" {
  source              = "./modules/bucket"
  environment         = "stage"
  create_user         = true
  bucket_name         = "developer-portal"
  eks_worker_role_arn = "${data.terraform_remote_state.eks-us-west-2.developer_portal_worker_iam_role_arn}"
  distribution_id     = "${module.cdn_stage.cloudfront_id}"
}

module "efs_stage" {
  source      = "./modules/storage"
  environment = "stage"
  subnets     = "${data.terraform_remote_state.vpc-us-west-2.private_subnets}"

  nodes_security_group = [
    "${data.terraform_remote_state.eks-us-west-2.developer_portal_worker_security_group_id}",
    "${data.terraform_remote_state.eks-us-west-2.mdn_apps_a_worker_security_group_id}",
    "${join(",", data.terraform_remote_state.kops-us-west-2.node_security_group_ids)}",
  ]
}

module "cdn_stage" {
  source          = "./modules/cdn"
  environment     = "stage"
  cdn_aliases     = ["developer-portal-stage.mdn.mozit.cloud", "developer-portal.stage.mdn.mozit.cloud", "developer-portal-published.stage.mdn.mozit.cloud"]
  origin_bucket   = "${module.bucket_stage.bucket_id}"
  certificate_arn = "${data.aws_acm_certificate.developer-portal-cdn-stage.arn}"
}

module "mail_stage" {
  source       = "./modules/mail"
  service_name = "dev-portal"
  environment  = "stage"
}

module "redis_stage" {
  source          = "./modules/redis"
  redis_id        = "developer-portal"
  environment     = "stage"
  redis_nodes     = "3"
  redis_node_type = "cache.t2.micro"
  subnets         = "${data.terraform_remote_state.vpc-us-west-2.public_subnets}"

  security_groups = [
    "${data.terraform_remote_state.eks-us-west-2.developer_portal_worker_security_group_id}",
    "${join(",", data.terraform_remote_state.kops-us-west-2.node_security_group_ids)}",
  ]
}

module "db_prod" {
  source         = "./modules/db"
  environment    = "prod"
  vpc_id         = "${data.terraform_remote_state.vpc-us-west-2.vpc_id}"
  identifier     = "developer-portal"
  instance_class = "db.t3.medium"
  db_name        = "developer_portal"
  db_user        = "${lookup(var.rds, "user.prod")}"
  db_password    = "${lookup(var.rds, "password.prod")}"
}

module "bucket_prod" {
  source              = "./modules/bucket"
  environment         = "prod"
  create_user         = true
  bucket_name         = "developer-portal"
  eks_worker_role_arn = "${data.terraform_remote_state.eks-us-west-2.developer_portal_worker_iam_role_arn}"
  distribution_id     = "${module.cdn_prod.cloudfront_id}"
}

module "cdn_prod" {
  source          = "./modules/cdn"
  environment     = "prod"
  cdn_aliases     = ["developer-portal.prod.mdn.mozit.cloud", "developer-portal-published.prod.mdn.mozit.cloud"]
  origin_bucket   = "${module.bucket_stage.bucket_id}"
  certificate_arn = "${data.aws_acm_certificate.developer-portal-cdn-prod.arn}"
}

module "redis_prod" {
  source          = "./modules/redis"
  redis_id        = "developer-portal"
  environment     = "prod"
  redis_nodes     = "3"
  redis_node_type = "cache.t2.medium"
  subnets         = "${data.terraform_remote_state.vpc-us-west-2.public_subnets}"

  security_groups = [
    "${data.terraform_remote_state.eks-us-west-2.developer_portal_worker_security_group_id}",
    "${join(",", data.terraform_remote_state.kops-us-west-2.node_security_group_ids)}",
  ]
}