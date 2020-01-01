# Role Based Access Control (RBAC)

## Assumptions
- You are familiar with <a href="https://kubernetes.io/docs/tutorials/kubernetes-basics/" target="_blank">Kubernetes</a>
- You are familiar with <a href="https://kubectl.docs.kubernetes.io/pages/kubectl_book/getting_started.html" target="_blank">kubectl</a>
- Many of the examples in this doc assume you are using Microk8s but can be easily modified to work with vanilla kubectl

## Helpful Links
- <a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/" target="_blank">RBAC Overview (Docs)</a>
- <a href="https://kubernetes.io/docs/reference/using-api/api-concepts/" target="_blank">API Concepts (Docs)</a>
- <a href="https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/" target="_blank">Configuring Service Accounts (Docs)</a>
- <a href="https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md" target="_blank">Reference Documentation accessing Service Account API Tokens (Docs)</a>
- <a href="https://jeremievallee.com/2018/05/28/kubernetes-rbac-namespace-user.html" target="_blank">Restrict User to one Namespace (Blog)</a>
- <a href="https://microk8s.io/#get-started" target="_blank">Launch A Kubernetes Cluster Quickly (Project)</a>
    - <a href="https://snapcraft.io/docs/installing-snapd" target="_blank">Installing Snap (Docs)</a>
    - <a href="https://github.com/ubuntu/microk8s/tree/master/microk8s-resources/actions" target="_blank">Helpful Starter Config Source from Microk8s (Github)</a>

## Before You Begin

!!! warning "Be aware"
    I recommended that you perform all RBAC examples within a throwaway Kubernetes cluster until you become more familiar with it.

    I recommend using <a href="https://microk8s.io/" target="_blank">Microk8s</a> to spin up a dev cluster fast.

??? note "Show me how to setup a kubernetes cluster with RBAC and Microk8s"
    ### Install latest stable version of Kubernetes via Snap
    ```console
    snap install microk8s --classic
    ```
    
    ### Install specified channel of Kubernetes via Snap
    ```console
    snap install microk8s --classic --channel=1.15/stable
    ```
    
    ### How to list available channels of Microk8s in Snap
    ```console
    snap info microk8s
    ```
    
    ### Enable RBAC in Microk8s
    ```console
    microk8s.enable rbac
    ```

    See <a href="https://microk8s.io/docs/" target="_blank">Microk8s Docs</a> for more information.

## The Basics

There are 4 main components to implementing RBAC in Kubernetes:

1. `Role` - Define a set of permissions to resources within a single namespace.
2. `ClusterRole` - Grant similar permissions to `Role` but scoped to the cluster (i.e. Nodes), across multiple namespaces or against non-resource endpoints.
3. `RoleBinding` - Grant permissions defined in a role to a user or group of users (or service accounts) within a namespace.
4. `ClusterRoleBinding` - Same as `RoleBinding` but cluster-wide.

### Examples

Lets perform some practical examples leveraging the above components.

#### Create a Service Account and Namespace

```console
cat <<EOF | microk8s.kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: dev
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dev-pod-user
  namespace: dev
EOF
```

!!! note
    **Service Accounts** are Namespaced which means a service account must be created for every namespace you plan to leverage them. 
    
    Although, you can grant cluster permissions to a Service Account it cannot be used outside the namespace it was created in. We will validate this further down.

#### Role

!!! example "Role definition"
    Let's define a Role called `full-access-to-pods` which we will grant access to the `pods` resource in the core API group (`""`) allowing all (`'*'`) API verbs. Basically granting full access to the `/api/v1/pods` Kubernetes API within the `dev` namespace.

    ```yaml
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: full-access-to-pods
      namespace: dev
    rules:
    - apiGroups:
      - ""
      resources:
      - pods
      verbs:
      - '*'
    ```

##### How do I find any of the following on an API resource?

1. If the resource is Namespaced (scoped to a namespace)
2. What API Group it's apart of
3. What Verbs are allowed

Resource names, shortnames, api groups, if the resource is namespaced (true/false), kind and allowed verbs are all available via the `microk8s.kubectl api-resources -o wide` command.

??? note "Show me how to obtain API Resource details via kubectl"
    ```console
    $ microk8s.kubectl api-resources -o wide
    NAME                              SHORTNAMES   APIGROUP                       NAMESPACED   KIND                                 VERBS
    bindings                                                                      true         Binding                              [create]
    componentstatuses                 cs                                          false        ComponentStatus                      [get list]
    configmaps                        cm                                          true         ConfigMap                            [create delete deletecollection get list patch update watch]
    endpoints                         ep                                          true         Endpoints                            [create delete deletecollection get list patch update watch]
    events                            ev                                          true         Event                                [create delete deletecollection get list patch update watch]
    limitranges                       limits                                      true         LimitRange                           [create delete deletecollection get list patch update watch]
    namespaces                        ns                                          false        Namespace                            [create delete get list patch update watch]
    nodes                             no                                          false        Node                                 [create delete deletecollection get list patch update watch]
    persistentvolumeclaims            pvc                                         true         PersistentVolumeClaim                [create delete deletecollection get list patch update watch]
    persistentvolumes                 pv                                          false        PersistentVolume                     [create delete deletecollection get list patch update watch]
    pods                              po                                          true         Pod                                  [create delete deletecollection get list patch update watch]
    podtemplates                                                                  true         PodTemplate                          [create delete deletecollection get list patch update watch]
    [snipped]
    horizontalpodautoscalers          hpa          autoscaling                    true         HorizontalPodAutoscaler              [create delete deletecollection get list patch update watch]
    cronjobs                          cj           batch                          true         CronJob                              [create delete deletecollection get list patch update watch]
    jobs                                           batch                          true         Job                                  [create delete deletecollection get list patch update watch]
    certificatesigningrequests        csr          certificates.k8s.io            false        CertificateSigningRequest            [create delete deletecollection get list patch update watch]
    leases                                         coordination.k8s.io            true         Lease                                [create delete deletecollection get list patch update watch]
    endpointslices                                 discovery.k8s.io               true         EndpointSlice                        [create delete deletecollection get list patch update watch]
    events                            ev           events.k8s.io                  true         Event                                [create delete deletecollection get list patch update watch]
    ingresses                         ing          extensions                     true         Ingress                              [create delete deletecollection get list patch update watch]
    ingresses                         ing          networking.k8s.io              true         Ingress                              [create delete deletecollection get list patch update watch]
    networkpolicies                   netpol       networking.k8s.io              true         NetworkPolicy                        [create delete deletecollection get list patch update watch]
    runtimeclasses                                 node.k8s.io                    false        RuntimeClass                         [create delete deletecollection get list patch update watch]
    poddisruptionbudgets              pdb          policy                         true         PodDisruptionBudget                  [create delete deletecollection get list patch update watch]
    podsecuritypolicies               psp          policy                         false        PodSecurityPolicy                    [create delete deletecollection get list patch update watch]
    clusterrolebindings                            rbac.authorization.k8s.io      false        ClusterRoleBinding                   [create delete deletecollection get list patch update watch]
    [snipped]
    ```

##### Now Lets apply the Role

```console
cat <<EOF | microk8s.kubectl apply -f -
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: full-access-to-pods
  namespace: dev
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - '*'
EOF
```

#### RoleBinding

Now that we created a new namespace called `dev`, a service account called `dev-pod-user` and a role called `full-access-to-pods` lets associate them together with a RoleBinding.

!!! example "RoleBinding definition"
    Let's define a RoleBinding called `full-access-to-pods-role-binding` which we will grant service account `dev-pod-user` access to the `full-access-to-pods` role.

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: full-access-to-pods-role-binding
      namespace: dev
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: full-access-to-pods
    subjects:
    - kind: ServiceAccount
      name: dev-pod-user
    ```

    See <a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding" target="_blank">Binding Documentation</a> for more information.

##### Now Lets apply the RoleBinding

```console
cat <<EOF | microk8s.kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: full-access-to-pods-role-binding
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: full-access-to-pods
subjects:
- kind: ServiceAccount
  name: dev-pod-user
EOF
```

!!! tldr
    In order to create a service account you need to target an existing namespace or create a new one.

    A role can be created without a specific service account in mind but also need to target an existing namespace or create a new one.

    When creating a RoleBinding you will need to target a namespace, an existing role (roleRef) in that namespace and a user, group, or service account (subject).

#### Using our new role

TODO
