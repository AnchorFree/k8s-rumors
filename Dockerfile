FROM anchorfree/k8s-toolbox:v0.5.0
LABEL maintainer="v.zorin@anchorfree.com"


COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
