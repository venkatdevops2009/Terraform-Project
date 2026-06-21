terraform {
  backend "s3" {
    bucket       = "petclinic1805"
    key          = "terraform-jenkins-tf-state"
    region       = "us-east-1"
    use_lockfile = true
  }
}