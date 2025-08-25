# Istio Multi-Cluster Deployment with Terraform

This Terraform configuration deploys Istio across two Kubernetes clusters.

### Architecture

```
┌─────────────────┐         ┌─────────────────┐
│   West Cluster  │         │   Asia Cluster  │
│   (us-west-2)   │◄────────┤ (ap-southeast-1)│
│                 │         │                 │
│ ┌─────────────┐ │         │ ┌─────────────┐ │
│ │ Istio CP    │ │         │ │ Istio CP    │ │
│ │ East-West   │ │         │ │ East-West   │ │
│ │ Gateway     │ │         │ │ Gateway     │ │
│ └─────────────┘ │         │ └─────────────┘ │
└─────────────────┘         └─────────────────┘
```

### Traffic Flow

#### Cross-Cluster Service Communication:

1) West → Asia Service Call
```
App Pod (West) → Envoy Sidecar (West) → East-West Gateway (West) → Internet → East-West Gateway (Asia) → Envoy Sidecar (Asia) → App Pod (Asia)
```

2) Asia → West Service Call
```
App Pod (Asia) → Envoy Sidecar (Asia) → East-West Gateway (Asia) → Internet → East-West Gateway (West) → Envoy Sidecar (West) → App Pod (West)
```

### Control Plane Communication:

1) Sidecar Configuration (Within Cluster)
```
Envoy Sidecar (West) → istiod (West)
Envoy Sidecar (Asia) → istiod (Asia)
```

2) Cross-Cluster Control Plane Access
```
Envoy Sidecar (West) → East-West Gateway (West) → East-West Gateway (Asia) → istiod (Asia)
Envoy Sidecar (Asia) → East-West Gateway (Asia) → East-West Gateway (West) → istiod (West)
```

### Service Discovery Flow:
```
istiod (West) ← Remote Secret → istiod (Asia)
istiod (Asia) ← Remote Secret → istiod (West)
```

### Gateway Exposure Ports:

1) East-West Gateway (Cross-Cluster Traffic)
```
Port 15443 (TLS) → Auto-Passthrough → Target Service
Port 15012 (TLS) → Passthrough → istiod Control Plane
```

### Security Layer (mTLS):
```
All traffic: Source → mTLS Encryption → East-West Gateway → mTLS Decryption → Destination
```

### Full End-to-End Example:
```
Web App (West) → Sidecar (West) → EW-Gateway (West) → Internet → EW-Gateway (Asia) → Sidecar (Asia) → Database (Asia)
                     ↓                                                                    ↑
              mTLS Certificate ────────────────── Shared CA ─────────────────── mTLS Certificate
```

### Quick Start

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Istio Basic Verification

1) Verify Istio Components Are Running

Check that all Istio pods are running in both clusters:

```bash
# Check each cluster Istio components
kubectl get pods -n istio-system

# Expected output:
# NAME                                    READY   STATUS    RESTARTS   AGE
# istio-eastwestgateway-xxx              1/1     Running   0          5m
# istiod-xxx                             1/1     Running   0          6m
```

2) Verify Remote Secrets Are Created

Confirm that remote secrets exist for cross-cluster service discovery:

```bash
# Check remote secrets in each cluster (should see opposite cluster secret)
kubectl get secrets -n istio-system | grep "istio-remote-secret"

# Expected output:
# istio-remote-secret-west-cluster   Opaque   1      5m
```

3) Verify Cross-Cluster Service Discovery

Check that clusters can discover each other's services:

```bash
# Check endpoints in each cluster (should include remote cluster endpoints)
kubectl get endpoints -n istio-system
```

4) Verify East-West Gateway External IPs

Confirm that east-west gateways have external LoadBalancer IPs assigned:

```bash
# Check each cluster east-west gateway
kubectl get svc istio-eastwestgateway -n istio-system

# Expected output:
# NAME                    TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)
# istio-eastwestgateway   LoadBalancer   10.100.x.x     <EXTERNAL-IP>    15021:xxx/TCP,15443:xxx/TCP
```

5) Verify Cross-Cluster Connectivity with istioctl

Use istioctl to verify the clusters can see each other:

```bash
# Check remote clusters status
istioctl remote-clusters

# From each cluster, check if it can see opposite cluster endpoints
istioctl proxy-config cluster deployment/istiod -n istio-system | grep asia

# Analyze overall mesh health
istioctl analyze

# Check istiod logs for cluster connection errors
kubectl logs deployment/istiod -n istio-system | grep -E "cluster|error"

# Test cross-cluster DNS (deploy test pod first)
kubectl run test-pod --image=curlimages/curl:latest --command -- sleep 3600
kubectl exec test-pod -- nslookup service-name.namespace.svc.cluster.local

# Verify remote secrets format
kubectl get secret istio-remote-secret-<CLUSTER-NAME> -n istio-system -o yaml
```

### Istio mTLS Verification and Canary deployment test

1) Verify PeerAuthentication Policies in both clusters
```shell
kubectl get peerauthentication -A
```

2)  Deploy Product page v1 in both clusters
```shell
cd kubernetes
k apply -n secure -f productpage.yaml
```

3) Check Basic App Functionality
```shell
kubectl port-forward deployment/productpage-v1 9080:9080 -n secure
```

4) Check mTLS status and certificates in Envoy
```shell
istioctl proxy-config cluster $(kubectl get pods -n secure -l app=productpage -o jsonpath='{.items[0].metadata.name}').secure --fqdn productpage.secure.svc.cluster.local

istioctl proxy-config secret $(kubectl get pods -n secure -l app=productpage -o jsonpath='{.items[0].metadata.name}').secure

istioctl proxy-config cluster $(kubectl get pods -n secure -l app=productpage -o jsonpath='{.items[0].metadata.name}').secure -o json | grep -A 10 -B 10 "transport_socket"

kubectl exec $(kubectl get pods -n secure -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n secure -- pilot-agent request GET certs
```

5) Security checks
```shell
# Create pod without sidecar - Test should FAIL
kubectl create namespace no-injection
kubectl run curl-test --image=curlimages/curl -n no-injection -- sleep 3600
kubectl exec curl-test -n no-injection -- curl productpage.secure.svc.cluster.local:9080 --max-time 10

# Create pod with sidecar - Test should PASS
kubectl run curl-test --image=curlimages/curl -n secure -- sleep 3600
kubectl exec curl-test -n secure -- curl -Is productpage.secure.svc.cluster.local:9080 --max-time 10
```

6) Deploy Product page v2 in one cluster
```shell
cd kubernetes
k apply -n secure -f productpage_v2.yaml
```

7) Modify the virtual service, apply the canary yaml on both the clusters
```shell
cd kubernetes
k apply -n secure -f virtual-service-canary.yaml
```

8) Expose and access the UI from first cluster and try refreshing it multiple times, you should notice that 2/10 the traffic gets routed to the v2 reviews, which is actually running on the remote cluster. 

9) Once you are confident, you can again modify the virtual service to route 100% traffic to the new version and delete the old deployments.
