FROM node:6-stretch-slim

# Container interface
ENV HEALTH_GIT_REPO=git://git.openstack.org/openstack/openstack-health \
    HEALTH_GIT_REF=master
EXPOSE 80

# Build dependencies
RUN apt-get update && apt-get install -q -y \
    git curl build-essential libssl-dev rsync

# Required packages
RUN apt-get install -q -y nginx python

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log; \
	  ln -sf /dev/stderr /var/log/nginx/error.log

# Install gulp
RUN npm install -g gulp

# Clone openstack-health
RUN git clone $HEALTH_GIT_REPO; \
    cd openstack-health; git checkout $HEALTH_GIT_REF; cd ..

# Install, build and deploy
RUN cd openstack-health; npm install; gulp prod; cd ..; \
    rsync -arPz --delete openstack-health/build/ /usr/share/nginx/html/

# Cleanup
RUN apt-get remove -q -y git curl build-essential libssl-dev rsync; \
    apt-get clean; apt-get purge -y --auto-remove

COPY run.sh .
CMD ./run.sh
