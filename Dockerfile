FROM alpine:3.8

RUN apk add --no-cache curl

WORKDIR /opt/app

ADD sidecar.sh /opt/app/

RUN chmod 777 sidecar.sh
RUN echo $APP_URL

CMD ["./sidecar.sh"]
