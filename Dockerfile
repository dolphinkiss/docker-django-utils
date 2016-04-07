FROM postgres:9.5
MAINTAINER Peter Lauri <peterlauri@gmail.com>

RUN apt-get update && apt-get upgrade -y && apt-get install -y
RUN apt-get install -y wget

# setup pip and virtualenv
RUN apt-get update
RUN apt-get install -y python-dev python-setuptools libpq-dev
RUN easy_install pip
RUN pip install --upgrade pip
RUN pip install virtualenv
RUN virtualenv /venv

RUN /venv/bin/pip install awscli

ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]