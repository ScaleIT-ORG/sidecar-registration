FROM alpine:3.8

RUN apk update && apk upgrade
RUN apk add --no-cache curl

WORKDIR /opt/app

ADD sidecar.sh /opt/app/

RUN chmod 777 sidecar.sh
RUN echo $APP_ID

CMD ["./sidecar.sh"]
