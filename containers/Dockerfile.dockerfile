FROM ghcr.io/pfm-powerforme/s6:latest AS s6
# 构建时
FROM docker.io/library/alpine:latest AS alpine-builder
ARG REPO
# eg. amd64 | arm64
ARG ARCH
# eg. x86_64 | aarch64
ARG CPU_ARCH
# eg. latest
ARG IMAGE_VERSION
ENV REPO=$REPO \
     ARCH=$ARCH \
     CPU_ARCH=$CPU_ARCH \
     IMAGE_VERSION=$IMAGE_VERSION
RUN apk add --no-cache tzdata ca-certificates


# 运行时
FROM docker.io/library/busybox:stable-musl AS runtime
ENV PATH="/command:/pfm/bin:/usr/sbin:/usr/bin:/bin" \
     S6_LOGGING_SCRIPT="n2 s1000000 T" \
     LC_ALL="C.UTF-8" \
     LANG="C.UTF-8" \
     TERM="xterm-256color" \
     COLORTERM="truecolor" \
     EDITOR="vi" \
     VISUAL="vi" \
     TMPDIR="/tmp" \
     TEMP="/tmp" \
     TMP="/tmp" \
     HISTCONTROL="ignoredups" \
     HISTSIZE="1000" \
     HISTFILESIZE="1000"

RUN ln -sfn /run /var/run
RUN addgroup -g 32760 syslog && \
     adduser -u 32760 -G syslog -H -h /var/log/syslogd -D -s /sbin/nologin syslog && \
     addgroup -g 32761 sysllog && \
     adduser -u 32761 -G sysllog -H -h /var/log/syslogd -D -s /sbin/nologin sysllog
# 文件补全
COPY --from=alpine-builder /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY --from=alpine-builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
# 工具
COPY --from=ghcr.io/pfm-powerforme/cli-envsubst:latest / /
COPY --from=ghcr.io/pfm-powerforme/cli-dasel:latest / /
# S6
COPY --from=s6 / /
RUN mkdir -pv /etc/s6-overlay/init-data/ && mkdir -pv /etc/s6-overlay/scripts
# 本地工具
COPY rootfs/ /
RUN chmod +x /pfm/bin/fix_env
RUN /pfm/bin/fix_env
ENTRYPOINT ["/init"]