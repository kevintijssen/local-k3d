FROM --platform=linux/amd64 alpine

RUN apk add --update supervisor nginx && \
    rm  -rf /tmp/* /var/cache/apk/*

COPY supervisord.conf /etc/
#COPY source dest
#COPY source dest

ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
