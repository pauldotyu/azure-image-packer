terraform {
  backend "remote" {
    organization = "contosouniversity"

    workspaces {
      name = "staygolden"
    }
  }
}