# syntax=docker/dockerfile:1
FROM nvidia/cuda:12.3.1-devel-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive

COPY install.sh /tmp
COPY Vary-master /app/Vary-master

WORKDIR /app/Vary-master

ENV MAMBA_ROOT_PREFIX=/root/micromamba
RUN apt-get update && \
    apt-get install -y git jq curl tar bzip2 libgl1-mesa-glx libglib2.0-0 && \
    echo "1" | /tmp/install.sh && \
    micromamba create -n varytoy python=3.10 -y -c conda-forge && \
    micromamba run -n varytoy python -m pip install . -i https://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn && \
    rm -rf /tmp/install.sh && \
    rm -rf /root/.cache/pip && \    
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    rm -rf /var/cache/apt/*

RUN micromamba run -n varytoy python -m pip install ninja -i https://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn && \
    micromamba run -n varytoy python -m pip install flash-attn --no-build-isolation -i https://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn


VOLUME ["/app/Vary-master/clip-vit-large-patch14", "/app/Vary-master/Varyweight"]

EXPOSE 58616

CMD ["micromamba", "run", "-n", "varytoy", "python", "-m", "vary.api", "--host", "0.0.0.0", "--port", "58616"]
