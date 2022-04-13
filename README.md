# TerraformOnAzureExample

## Compose file

```Terraform
version: '3.8'

services:
  ansiblecontainer:
    image: gustavmk/ansiblecontainer:latest
    volumes:
      - .:/work
    working_dir: Work
    environment:
      - ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}
      - ARM_CLIENT_ID=${ARM_CLIENT_ID}
      - ARM_TENANT_ID=${ARM_TENANT_ID}
      - ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET}
```

Run

```Bash
docker-compose run --rm ansiblecontainer "terraform fmt ; terraform validate"
docker-compose run --rm ansiblecontainer "terraform init"
docker-compose run --rm ansiblecontainer "terraform plan -out plan.tfplan"
docker-compose run --rm ansiblecontainer "terraform apply plan.tfplan"
```
