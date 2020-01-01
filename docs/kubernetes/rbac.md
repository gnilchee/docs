# Role Based Access Control (RBAC)

## Helpful Links
- <a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/" target="_blank">RBAC Overview (Docs)</a>
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

??? note "Show me how to setup a kubernetes cluster with RBAC"
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