FROM python:3.5-slim

# add a non-privileged user for installing and running
# the application
RUN groupadd -g 9000 kinto && \
    useradd -M -u 9000 -g 9000 -G kinto -d /kinto-dist -s /sbin/nologin kinto

COPY . /kinto-dist
WORKDIR /kinto-dist

RUN buildDeps=' \
    git \
    gcc \
    libffi-dev \
    libldap2-dev \
    libpq-dev \
    libsasl2-dev \
    libssl-dev \
    libxml2-dev \
    ' && \
    # install deps
    apt-get update -y && \
    apt-get install -y --no-install-recommends $buildDeps && \
    pip install -e . -c requirements.txt && \
    pip install uwsgi && uwsgi --build-plugin https://github.com/Datadog/uwsgi-dogstatsd && \

    # construct version.json
    GITREF=$(git rev-parse HEAD) \
    GITTAG=$(git name-rev --tags --name-only $GITREF) \
    SOURCE='https://github.com/mozilla-services/kinto-dist' && \
    echo "{\"source\": \"$SOURCE\", \"name\": \"kinto-dist\", \"version\": \"$GITTAG\", \"commit\": \"$GITREF\"}" > version.json && \

    # cleanup
    apt-get purge -y $buildDeps && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf uwsgi-dogstatsd

# Drop down to unprivileged user
USER kinto

# Run uwsgi by default
CMD ["uwsgi", "--ini", "/etc/kinto-dist/kinto.ini"]
