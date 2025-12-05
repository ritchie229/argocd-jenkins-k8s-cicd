kubectl run -n default -it --rm dns-test --image=busybox --restart=Never -- nslookup github.com

