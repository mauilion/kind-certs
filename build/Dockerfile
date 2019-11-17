FROM mauilion/node:v1.16.3-10m
ADD https://k8s.work/kubeadm /usr/bin/kadm
RUN chmod +x /usr/bin/kadm
ENTRYPOINT ["/usr/local/bin/entrypoint", "/sbin/init"]

