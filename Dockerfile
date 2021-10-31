FROM golang:1.17.2-alpine3.14
MAINTAINER jasonkayzk@gmail.com
RUN mkdir /app
COPY . /app
WORKDIR /app
RUN go build -o main .
CMD ["/app/main"]