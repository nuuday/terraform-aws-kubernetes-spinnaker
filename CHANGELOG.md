
<a name="0.1.0"></a>
## [0.1.0](https://github.com/nuuday/terraform-aws-kubernetes-spinnaker/compare/0.0.3...0.1.0) (2020-08-07)

### Feat

* removed additional kube configs and moved them to a specific secret


<a name="0.0.3"></a>
## [0.0.3](https://github.com/nuuday/terraform-aws-kubernetes-spinnaker/compare/0.0.2...0.0.3) (2020-07-24)

### Fix

* Fixed namespace argument to helm


<a name="0.0.2"></a>
## [0.0.2](https://github.com/nuuday/terraform-aws-kubernetes-spinnaker/compare/0.0.1...0.0.2) (2020-07-24)

### Fix

* Changed action to hash and added README.md


<a name="0.0.1"></a>
## 0.0.1 (2020-07-24)

### Chore

* formatting
* added changelog configuration and template

### Feat

* added support for helm repositories
* Added module to create the correct spinnaker roles and bindings, this can also create a namespace
* Added support for setting ssm settings via module
* Added support for more the the default account
* Added oauth and ingress support

### Fix

* Added metrics permissions to RBAC
* formatting
