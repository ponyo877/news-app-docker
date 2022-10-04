FROM golang:1.18.1-alpine AS build
WORKDIR /src
RUN apk update && apk add git
RUN git clone --depth 1 -b develop https://github.com/ponyo877/news-app-backend-refactor.git /src
RUN go mod download
RUN go build -o /news-app api/main.go

FROM alpine:latest
WORKDIR /
COPY --from=build /news-app /news-app
EXPOSE 80
ENTRYPOINT ["/news-app"]