FROM debian:stretch-slim

RUN apt-get update && \
  apt-get install -yq wget parted bash pv p7zip-full file unzip gawk kpartx proot qemu qemu-user-static binfmt-support && \
  apt-get clean
  
RUN cd / && \
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh && \
chmod +x pishrink.sh

COPY sys/customPIze-magic.sh /
ENV PATH="/:${PATH}"

WORKDIR /
CMD customPIze-magic.sh
