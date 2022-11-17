FROM golang:1.18.1-alpine AS build
WORKDIR /src
RUN apk update && apk add git gcc make g++ libgcc libstdc++
RUN git clone --depth 1 -b develop https://github.com/ponyo877/news-app-backend-refactor.git /src
RUN go mod download
RUN go build -o /news-app api/main.go

FROM alpine:latest
WORKDIR /
RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
COPY --from=build /news-app /news-app
EXPOSE 80
ENTRYPOINT ["/news-app"]