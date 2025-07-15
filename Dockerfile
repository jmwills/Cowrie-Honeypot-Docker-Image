FROM alpine:3.12

# Copy local config and dependency files into the image
COPY dist/ /root/dist/

# Install system packages and Python (pinned version for reproducibility)
RUN sed -i 's/dl-cdn/dl-2/g' /etc/apk/repositories && apk -U add \
    bash \
    build-base \
    git \
    gmp-dev \
    libcap \
    libffi-dev \
    mpc1-dev \
    mpfr-dev \
    openssl \
    openssl-dev \
    py3-pip \
    python3=3.8.12-r0 \
    python3-dev \
    py3-bcrypt \
    py3-mysqlclient \
    py3-requests \
    py3-setuptools && \
\
# Create non-root user to run Cowrie
    addgroup -g 2000 cowrie && \
    adduser -S -s /bin/ash -u 2000 -D -g 2000 cowrie && \
\
# Clone Cowrie and install its dependencies
    mkdir -p /home/cowrie && \
    cd /home/cowrie && \
    git clone --depth=1 https://github.com/micheloosterhof/cowrie -b v2.1.0 && \
    cd cowrie && \
    sed -i 's/logfile\.DailyLogFile/logfile.LogFile/' src/cowrie/python/logfile.py && \
    mkdir -p log && \
    cp /root/dist/requirements.txt . && \
    pip3 install -r requirements.txt && \
\
# Configure Cowrie and set permissions
    export PYTHON_DIR=$(python3 --version | tr '[A-Z]' '[a-z]' | tr -d ' ' | cut -d '.' -f 1,2 ) && \
    setcap cap_net_bind_service=+ep /usr/bin/$PYTHON_DIR && \
    cp /root/dist/cowrie.cfg /home/cowrie/cowrie/cowrie.cfg && \
    chown cowrie:cowrie -R /home/cowrie/* /usr/lib/$PYTHON_DIR/site-packages/twisted/plugins && \
\
# Pre-run Cowrie once to avoid startup issues
    su - cowrie -c "export PYTHONPATH=/home/cowrie/cowrie:/home/cowrie/cowrie/src && \
                    cd /home/cowrie/cowrie && \
                    /usr/bin/twistd --uid=2000 --gid=2000 -y cowrie.tac --pidfile cowrie.pid cowrie &" && \
    sleep 10 && \
\
# Clean up build tools and temporary files
    apk del --purge \
        build-base \
        git \
        gmp-dev \
        libcap \
        libffi-dev \
        mpc1-dev \
        mpfr-dev \
        openssl-dev \
        python3-dev \
        py3-mysqlclient && \
    rm -rf /root/* /tmp/* /var/cache/apk/* /home/cowrie/cowrie/cowrie.pid

# Set runtime environment
ENV PYTHONPATH=/home/cowrie/cowrie:/home/cowrie/cowrie/src
WORKDIR /home/cowrie/cowrie
USER cowrie:cowrie
CMD ["/usr/bin/twistd", "--nodaemon", "-y", "cowrie.tac", "--pidfile", "/tmp/cowrie/cowrie.pid", "cowrie"]
