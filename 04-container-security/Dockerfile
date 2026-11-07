FROM nginxinc/nginx-unprivileged:stable-alpine

USER root

RUN apk upgrade --no-cache

COPY nginx-security/nginx.conf /etc/nginx/nginx.conf
COPY nginx-security/default.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html

RUN nginx -t

USER 101
