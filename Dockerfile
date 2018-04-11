FROM alpine:3.7

RUN apk update && apk upgrade
RUN apk add curl

WORKDIR /opt/app

ADD ./ /opt/app/

RUN chmod 777 sidecar.sh
RUN echo $APP_ID

CMD ["./sidecar.sh"]
