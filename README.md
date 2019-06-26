# About

Minimal example app for lab under devops-sigs-8.

# Use case

We want to invoke app restart in pod in case of configmap update.
Solution in here is to use inotify to detect config file change and killing processes in shared namespace within a kubernetes pod.

# Video

https://youtu.be/mzuFoO6SWqk

Steps to reproduce:

- ensure to have a working kubernetes context
- `kubectl apply -f k8s/`
- wait for replicas to come online
- change config in `k8s/configmap.yaml`
- run `kubectl apply -f k8s/` again to trigger configmap update
- wait till configmap change is propagated across pods
- see how pods are getting restarted in random fashion
- look at the panels in the video.

    + top left - services and endpoints, watch out for Endpoints.
    + top right - pods from deployments, watch out for Restarts.
    + bottom left - main apply console
    + bottom right - logs streamed with https://github.com/wercker/stern


Notice how long it takes between kubectl apply and actual config change
in the volume in pods and how random it is.

When configmap is updated with kubectl then we must wait until
they are updated in each pod (random time from 0 to about 60 seconds).
When configmap updated in volume then `watcher` container will detect the  change and will trigger killing of all processes in pod (because of the shared namespace). There is a log generated in such event.

As we can see on the video it may lead to service unavailability - no endpoints marked as healthy due to liveness probes.

# Conclusions
Don't use it, it's not safe because configmap updates in pod are in random
or depend on caching and so on. This solution may lead to service disruption,
especially if replica count is low.

Suggested solutions:

- create new configmap and run new deployment (safest)
- ensure your app is aware of config updates and reloads itself when config is changed and if it is valid
- you may use https://github.com/stakater/Reloader
- alternatives confd, envtpl, dynamic config from outside of k8s (consul?)

# Quick howtos

## Creating k8s cluster using `kind`

linux (make sure you have docker installed already)
```shell

curl -Lo ./kind-linux-amd64 https://github.com/kubernetes-sigs/kind/releases/download/v0.4.0/kind-linux-amd64
chmod +x ./kind-linux-amd64
mkdir ~/bin
mv ./kind-linux-amd64 ~/bin/kind

kind create cluster
export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
kubectl cluster-info
```


## Build container

```shell
export DOCKER_USER=kaszpir
export DOCKER_PASS=hunter2
make all
```

# Kubernetes related

## Test with kubeval

```shell
make kubeval
```

## Deploy on k8s

Remember to have proper k8s context active
```shell
kubectl apply -f k8s/
```

# Scale test
first create example deployment:
```shell
make k8s
make k8s_scale_2
make ab_long
```

then in another terminal:
```shell
make k8s_scale_2
```
then see if apachebench returns any failed requests, it should not
```text
Failed requests:        0
```

example:
```
17:48:53 kaszpir@misiek ~/src/devops-sig-8  (misiek) $ make ab_long
kubectl run -i --rm --restart=Never --image=mocoso/apachebench apachebench -- bash -c "ab -n 100000 -c 10 http://devops-sig-8/time"
If you don't see a command prompt, try pressing enter.

Completed 10000 requests
Completed 20000 requests
Completed 30000 requests
Completed 40000 requests
Completed 50000 requests
Completed 60000 requests
Completed 70000 requests
Completed 80000 requests
Completed 90000 requests
Completed 100000 requests
Finished 100000 requests


Server Software:        gunicorn/19.9.0
Server Hostname:        devops-sig-8
Server Port:            80

Document Path:          /time
Document Length:        10 bytes

Concurrency Level:      10
Time taken for tests:   51.278 seconds
Complete requests:      100000
Failed requests:        0
Total transferred:      16200000 bytes
HTML transferred:       1000000 bytes
Requests per second:    1950.16 [#/sec] (mean)
Time per request:       5.128 [ms] (mean)
Time per request:       0.513 [ms] (mean, across all concurrent requests)
Transfer rate:          308.52 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.1      0       8
Processing:     0    5   1.8      4      30
Waiting:        0    5   1.8      4      28
Total:          1    5   1.8      4      30

Percentage of the requests served within a certain time (ms)
  50%      4
  66%      5
  75%      6
  80%      6
  90%      8
  95%      9
  98%     10
  99%     11
 100%     30 (longest request)
pod "apachebench" deleted
```

