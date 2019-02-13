FROM nginx:latest

# Container interface
ENV HEALTH_GIT_REPO=git://git.openstack.org/openstack/openstack-health \
    HEALTH_GIT_REF=master

# Build dependencies
RUN apt-get update && apt-get install -q -y \
    git curl build-essential libssl-dev rsync

RUN curl -sLO https://deb.nodesource.com/setup_6.x \
    && bash setup_6.x \
    && apt-get -y install nodejs

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
