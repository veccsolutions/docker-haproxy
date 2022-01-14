ARG lua_version=5.4

FROM alpine:latest AS build
ARG lua_version

RUN apk add --no-cache git \
        build-base \
        libexecinfo-dev \
        linux-headers \
        lua${lua_version}-dev \
        openssl-dev \
        pcre2-dev \
        zlib-dev

WORKDIR /build
RUN git clone https://github.com/haproxy/haproxy.git

WORKDIR haproxy
RUN git checkout `git tag | grep -v ".*-dev" | tail -1`

RUN make -j$(nproc) \
        TARGET=custom \
        EXTRA_OBJS="addons/promex/service-prometheus.o" \
        USE_OPENSSL=1 \
        USE_PCRE2=1 \
        USE_ZLIB=1 \
        USE_THREAD=1

##########################################################

FROM alpine:latest

RUN apk add --no-cache \
        pcre2

RUN mkdir /run/haproxy \
        && mkdir /var/lib/haproxy \
        && chmod 0777 /run/haproxy
COPY --from=build /build/haproxy/haproxy /

ENTRYPOINT ["/haproxy"]