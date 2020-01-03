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

Let's perform some practical exercises leveraging the above components.

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
    We defined a Role called `full-access-to-pods` which we will grant access to the `pods` resource in the core API group (`""`) allowing all (`'*'`) API verbs. Basically granting full access to the `/api/v1/pods` Kubernetes API within the `dev` namespace.

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

##### Apply the Role

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

Now that we created a new namespace called `dev`, a service account called `dev-pod-user` and a role called `full-access-to-pods` and associate them together with a RoleBinding.

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

##### Now apply the RoleBinding

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

Now let's add a sample deployment to the `dev` namespace based on Istio's <a href="https://github.com/istio/istio/blob/master/samples/httpbin/httpbin.yaml" target="_blank">httpbin</a> sample application.

##### Deploy a reference pod

The sample application deployment will launch a single pod with a python based application which will use the default service account in the `dev` namespace. Refer to <a href="https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#use-the-default-service-account-to-access-the-api-server" target="_blank">Kubernetes documentation</a> to get more information on the default behavior when launching a pod.

```console
cat <<EOF | microk8s.kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
EOF
```

!!! example "Now confirm the Service Account used for the Pod"

    Below we confirmed that the deployment launched the pod with the `default` service account.
    ```console
    $ microk8s.kubectl get pod httpbin-768b999cb5-5c4cl -n dev -o yaml| grep serviceAccountName
      serviceAccountName: default
    ```

    Also note that Kubernetes automatically mounts the default token into the pod
    ```console
    $ microk8s.kubectl get pod httpbin-768b999cb5-5c4cl -n dev -o yaml
    apiVersion: v1
    kind: Pod
    metadata:
    [snipped]
      name: httpbin-768b999cb5-5c4cl
    [snipped]
        volumeMounts:
        - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
          name: default-token-nlzgt
          readOnly: true
    ```

    Exec into the httpbin container and see what data gets mounted in as a result
    ```console
    root@httpbin-768b999cb5-5c4cl:/# ls -l /var/run/secrets/kubernetes.io/serviceaccount
    total 0
    lrwxrwxrwx 1 root root 13 Jan  3 04:08 ca.crt -> ..data/ca.crt
    lrwxrwxrwx 1 root root 16 Jan  3 04:08 namespace -> ..data/namespace
    lrwxrwxrwx 1 root root 12 Jan  3 04:08 token -> ..data/token

    root@httpbin-768b999cb5-5c4cl:/# cat /var/run/secrets/kubernetes.io/serviceaccount/namespace; echo
    dev

    root@httpbin-768b999cb5-5c4cl:/# cat /var/run/secrets/kubernetes.io/serviceaccount/token; echo
    eyJhbGciOiJSUzI1NiIsImtpZCI6Ikxh...EsHorrcKBTnSa10OORjOrFpg
    ```

###### How can we leverage the service account

We now know that Kubernetes automatically assigns a service account and mounts in the token and namespace which can be leveraged by tools such as `kubectl` and Kubernetes client libraries. Let's see how this can be useful and add `kubectl` to the container and attempt to perform some commands and see if anything special is needed to get it to work.

!!! example "Issue commands from within the Pod container"

    First we download `kubectl` binary down to the Microk8s instance
    ```console
    $ curl -s -LO https://storage.googleapis.com/kubernetes-release/release/v1.17.0/bin/linux/amd64/kubectl
    $ chmod +x kubectl
    $ ls
    kubectl  snap
    ```

    Now we copy the `kubectl` into the Pod's container
    ```console
    $ microk8s.kubectl get pods -n dev
    NAME                       READY   STATUS    RESTARTS   AGE
    httpbin-768b999cb5-5c4cl   1/1     Running   0          44m
    $ microk8s.kubectl cp kubectl dev/httpbin-768b999cb5-5c4cl:/tmp/kubectl
    $
    ```

    Finally, let's exec into the container and run the `/tmp/kubectl get pods` command
    ```console
    $ microk8s.kubectl exec -it httpbin-768b999cb5-5c4cl -n dev -- /bin/bash
    root@httpbin-768b999cb5-5c4cl:/# /tmp/kubectl get pods
    Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:dev:default" cannot list resource "pods" in API group "" in the namespace "dev"
    ```

###### Review

Examining what we know so far is that by default when we don't define a service account Kubernetes will automatically assign one and mount in the account's token and the namespace of the pod which we can use a tool like `kubectl` to execute commands. Looking specifically at the above example we can see that by running `/tmp/kubectl get pods` it can determine the pod's namespace and token to use by looking in that directory.


!!! question
    How does `kubectl` know what endpoint to issue calls against to hit the Kubernetes API?

!!! example "It turns out Kubernetes injects env vars into the pod"

    ```console
    root@httpbin-768b999cb5-5c4cl:/# env| grep -i kubernetes
    KUBERNETES_PORT_443_TCP_PROTO=tcp
    KUBERNETES_PORT_443_TCP_ADDR=10.152.183.1
    KUBERNETES_PORT=tcp://10.152.183.1:443
    KUBERNETES_SERVICE_PORT_HTTPS=443
    KUBERNETES_PORT_443_TCP_PORT=443
    KUBERNETES_PORT_443_TCP=tcp://10.152.183.1:443
    KUBERNETES_SERVICE_PORT=443
    KUBERNETES_SERVICE_HOST=10.152.183.1
    ```

    If we unset the `KUBERNETES_SERVICE_HOST` var we confirm it breaks `kubectl`
    ```console
    root@httpbin-768b999cb5-5c4cl:/# unset KUBERNETES_SERVICE_HOST
    root@httpbin-768b999cb5-5c4cl:/# /tmp/kubectl get pods
    The connection to the server localhost:8080 was refused - did you specify the right host or port?
    ```

##### Deploy a pod that uses our new role

Since we now know what happens when we launch a pod with the `default` service account let's launch a new pod that will use the `dev-pod-user` service account and the `full-access-to-pods` role we created earlier.

We will launch a new deployment called `deb-test` and assign the new service account `dev-pod-user` into the `dev` namespace.

```console
cat <<EOF | microk8s.kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deb-test
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: deb-test
  template:
    metadata:
      labels:
        app: deb-test
    spec:
      serviceAccountName: dev-pod-user
      containers:
      - image: debian:latest
        imagePullPolicy: IfNotPresent
        name: deb-test
        command:
          - sleep
          - "3600"
      restartPolicy: Always
EOF
```

!!! example "Now confirm the Service Account used for the new Pod"

    We first confirm the new deployment launched the pod with the `dev-pod-user` service account.
    ```console
    $ microk8s.kubectl get pod deb-test-669c58cc9d-99gz4 -n dev -o yaml| grep serviceAccountName
      serviceAccountName: dev-pod-user
    ```

    Also confirm that Kubernetes mounts the `dev-pod-user` token into the pod
    ```console
    $ microk8s.kubectl get pod deb-test-669c58cc9d-99gz4 -n dev -o yaml
    apiVersion: v1
    kind: Pod
    metadata:
    [snipped]
      name: deb-test-669c58cc9d-99gz4
      namespace: dev
    [snipped]
        volumeMounts:
        - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
          name: dev-pod-user-token-mngkj
          readOnly: true
    ```

###### Now we leverage the new service account

Great! We confirmed that with our new deployment Kubernetes assigned the `dev-pod-user` service account and mounted in the token and namespace as it did with our reference deployment. Let's repeat the test from before but it will now use our new role.

!!! example "Issue commands from within the new Pod container"

    Since we already downloaded the `kubectl` binary we just need to copy it into the new container
    ```console
    $ microk8s.kubectl get pods -n dev| grep deb-test
    deb-test-669c58cc9d-99gz4   1/1     Running   0          10m
    $ microk8s.kubectl cp kubectl dev/deb-test-669c58cc9d-99gz4:/tmp/kubectl
    $
    ```

    Now let's exec into the deb-test container and run `/tmp/kubectl get pods` again and see if we still get a permission error
    ```console
    $ microk8s.kubectl exec -it deb-test-669c58cc9d-99gz4 -n dev -- /bin/bash
    root@deb-test-669c58cc9d-99gz4:/# /tmp/kubectl get pods
    NAME                        READY   STATUS    RESTARTS   AGE
    deb-test-669c58cc9d-99gz4   1/1     Running   0          13m
    httpbin-768b999cb5-5c4cl    1/1     Running   0          111m
    ```

    Let's also try to delete another pod in the `dev` namespace and confirm that also works
    ```console
    root@deb-test-669c58cc9d-99gz4:/# /tmp/kubectl delete pod httpbin-768b999cb5-5c4cl
    pod "httpbin-768b999cb5-5c4cl" deleted
    root@deb-test-669c58cc9d-99gz4:/# /tmp/kubectl get pods
    NAME                        READY   STATUS    RESTARTS   AGE
    deb-test-669c58cc9d-99gz4   1/1     Running   0          23m
    httpbin-768b999cb5-dtwhd    1/1     Running   0          13s
    ```

    🎉🎉🎉 Success! We are now able to get and delete pods in the dev namespace. Our role works as expected.

We confirmed that by using our new service account and role we created earlier we have full access to the pod API in the `dev` namespace. Like we mentioned in the <a href="#the-basics">The Basics</a> section a Role only applies to the namespace it was created in. Let's attempt to get pods again but across all namespaces.

!!! question
    What happens across namespaces?

!!! example "We get a different permission error"

    ```console
    root@deb-test-669c58cc9d-99gz4:/# /tmp/kubectl get pods --all-namespaces
    Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:dev:dev-pod-user" cannot list resource "pods" in API group "" at the cluster scope
    ```

    🔥🔥🔥 It fails with another permission issue but we expected this one.

###### Review

As expected, we get a permission error in the above example saying that you cannot list resource "pods" at the cluster scope in the core API group. Basically, in order to list pods outside the `dev` namespace we will need to create a ClusterRole (cluster scoped).

#### ClusterRole

TODO
