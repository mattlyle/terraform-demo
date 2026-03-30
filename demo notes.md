```
cd terraform/0-networking-infra
terraform apply

cd terraform/1-eks-infra
terraform apply

cd terraform/2-post-eks-infra
terraform apply

cd terraform/3-rds-infra
terraform apply

cd terraform/4-sqs-infra
terraform apply

aws eks update-kubeconfig --region us-east-1 --name matt-lyle-terraform-demo-eks

cd scripts
./install-concourse-eks.sh
```

get the URL to concourse:
```
k get service -n concourse concourse-web  --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

goto that URL on port :8080
admin/admin

```
./set-pipelines.sh
```
from GUI show concourse is running and pipelines exist.  run a plan

from GUI: install-ingress


---

lock down overnight
```
kubectl patch svc ingress-nginx-controller -n ingress-nginx \
  -p '{"spec":{"loadBalancerSourceRanges":["73.34.142.13/32"]}}'

kubectl patch svc concourse-web -n concourse \
  -p '{"spec":{"loadBalancerSourceRanges":["73.34.142.13/32"]}}'
```

open up before demo
```
kubectl patch svc ingress-nginx-controller -n ingress-nginx \
  -p '{"spec":{"loadBalancerSourceRanges":null}}'

kubectl patch svc concourse-web -n concourse \
  -p '{"spec":{"loadBalancerSourceRanges":null}}'
```
