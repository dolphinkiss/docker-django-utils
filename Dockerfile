FROM ubuntu:14.04
MAINTAINER Peter Lauri <peterlauri@gmail.com>

RUN apt-get update && apt-get upgrade -y && apt-get install -y
RUN apt-get install -y wget
RUN apt-get install -y postgresql-client

CMD ["/bin/true"]
