FROM centos:7

ARG S6_OVERLAY_VERSION=v1.21.2.2
ARG S6_OVERLAY_SHA256=50f67ae51e92eed8679d1a9027c971e809d27e788b3f0322b07fc6e8b9839ec0

RUN set -eux && \
    curl -sL -o /tmp/s6-overlay-amd64.tar.gz "https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" && \
    echo "${S6_OVERLAY_SHA256}  /tmp/s6-overlay-amd64.tar.gz" | sha256sum -c && \
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C / --exclude="./bin" && \
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C /usr ./bin && \
    rm -f /tmp/s6-overlay-amd64.tar.gz


RUN set -eux && \
    yum install -y \
        freeradius freeradius-{mysql,postgresql,utils} \
        samba-winbind-clients \
    && \
    yum clean all

RUN usermod -a -G wbpriv radiusd

ADD ./files /

# s6-overlay must run as root. but we can launch service as normal account
USER root
ENTRYPOINT [ "/init" ]

VOLUME [ "/data" ]
