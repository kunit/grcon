FROM golang:latest
RUN apt-get -qq update && \
    apt-get install -qq build-essential \
    vim
ADD . /go/src/github.com/kunit/grcon
WORKDIR /go/src/github.com/kunit/grcon
