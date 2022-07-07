# How to Connect to EKS

- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

Assumptions

- The AWS IAM role is created `arn:aws:iam::XXXX:role/github-oidc-provider-aws`
- With `Statement` to be set, as the action should be able to pull a kubeconfig

```json
 "Statement": [
  {
      "Action": "eks:DescribeCluster",
      "Effect": "Allow",
      "Resource": [
          "arn:aws:eks:REGION:XXXXX:cluster/<cluster-name>"
      ],
      "Sid": "AwsEksGetDescribeToPullKubeConfig"
  },
 ]
```

- As well as `Trust relationships` looks as belov

```json
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
              "Federated": "arn:aws:iam::XXX:oidc-provider/token.actions.githubusercontent.com"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
              "StringLike": {
                  "token.actions.githubusercontent.com:sub": "repo:<GithubORG>/<repository>:ref:refs/heads/main"
              }
          }
      }
  ]
}
```

- Next step is to update `kubectl edit configmap aws-auth -n kube-system`. Add following line

```yml
apiVersion: v1
data:
  mapRoles: |
    - rolearn: arn:aws:iam::XXXXX:role/github-oidc-provider-aws
      username: github-action
      groups:
       - support:github-action
```

Where `support:github-action` is a role with

Example `app-access` role for namespace `app`. CMD `kubectl get role app-access -o yaml`

```yml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    description: namespace-access
  name: app-access
  namespace: app
rules:
- apiGroups:
  - ""
  resources:
  - '*'
  verbs:
  - '*'
- apiGroups:
  - extensions
  resources:
  - '*'
  verbs:
  - '*'
```

And role binding is `managed:app-access` . Command `kubectl get rolebinding managed:app-access -o yaml`

```yml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: "2022-04-28T08:42:40Z"
  name: managed:app-access
  namespace: app
  resourceVersion: "6634"
  uid: 4bc413a0-8984-49bf-9530-0b03bd2a6849
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: support:operator
  namespace: default
```

**Notes**

> It seems that you have no other ways in Kubernetes to do it. There is no object like Group that you can "get" inside the Kubernetes configuration. Group information in Kubernetes is currently provided by the Authenticator modules and usually it's just string in the user property.
