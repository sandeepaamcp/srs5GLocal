FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      iproute2 \
      iputils-ping \
      libboost-program-options1.74.0 \
      libfftw3-single3 \
      libmbedcrypto7 \
      libzmq5 && \
    rm -rf /var/lib/apt/lists/*

COPY docker/ue/run_srsue.sh /usr/local/bin/run_srsue.sh

RUN chmod +x /usr/local/bin/run_srsue.sh

ENTRYPOINT ["/usr/local/bin/run_srsue.sh"]
