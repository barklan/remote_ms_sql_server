FROM ubuntu:hirsute-20210723

WORKDIR /app/

ARG DEBIAN_FRONTEND=noninteractive

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN apt-get update && apt-get install -y python3 python3-pip python-is-python3 nodejs npm curl

# * install dependencies
RUN python3 -m pip install --upgrade pip wheel Commitizen sqlfluff pre-commit codespell

RUN npm install -g jscpd
