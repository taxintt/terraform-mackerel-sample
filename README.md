# terraform-mackerel-sample

## create API key in ParameterStore
```
aws ssm put-parameter \
    --name "/mackerel/test-staging-org/apikey" \
    --value "${MACKEREL_APIKEY}" \
    --type "SecureString"
```

## terraform init
```
ENV=staging make init
```

## terraform plan
```
ENV=staging make plan
```

## terraform apply
```
ENV=staging make apply
```