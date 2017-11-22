FROM node:boron

WORKDIR /opt/app

ADD ./ /opt/app/

RUN chmod 777 sidecar.sh

CMD ["./sidecar.sh"]