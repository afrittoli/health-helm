FROM python:3.6-slim-stretch

# Container interface
ENV HEALTH_GIT_REPO=git://git.openstack.org/openstack/openstack-health \
    HEALTH_GIT_REF=master
EXPOSE 80

# Build dependencies
RUN apt-get update && apt-get install -q -y \
    build-essential musl-dev libxml2-dev git

# Required apt packages
RUN apt-get install -q -y nginx supervisor memcached libpq-dev
# Required pip packages
RUN pip3 install --no-cache-dir -U psycopg2 uwsgi

# Configuring nginx and uwsgi
RUN rm -f /etc/nginx/conf.d/default.conf; \
    rm -rf /etc/nginx/sites-enabled; \
    mkdir -p /etc/nginx/sites-enabled; \
    ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log; \
    echo "daemon off;" >> /etc/nginx/nginx.conf

# Install openstack-health
RUN git clone $HEALTH_GIT_REPO; \
    cd openstack-health; git checkout $HEALTH_GIT_REF

# Install requirements first to avoid reinstalling on code changes
RUN pip3 install --no-cache-dir -r ./openstack-health/requirements.txt
RUN pip3 install --no-cache-dir -U ./openstack-health

# Cleanup
RUN apt-get remove -q -y build-essential musl-dev libxml2-dev git; \
    apt-get clean; apt-get purge -y --auto-remove

# Deploy configuration from the context
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY health-api.conf /etc/nginx/sites-available/health-api.conf
COPY health-uwsgi-api.ini /etc/health-uwsgi-api.ini
COPY openstack-health.conf /etc/openstack-health.conf

# Enable Health Site and remove others
RUN ln -s /etc/nginx/sites-available/health-api.conf /etc/nginx/sites-enabled/health-api.conf

COPY run.sh /root/run.sh

CMD /root/run.sh
