# About

Minimal example app for lab under devops-sigs-8.

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

