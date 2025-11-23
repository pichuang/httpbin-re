# httpbin-re: HTTP Request & Response Service

Updates and **RE**build based on [Kenneth Reitz](http://kennethreitz.org/bitcoin)'s project

![tw ice cream](/images/tw-ice-cream.jpg)

Run locally:

```sh
docker pull ghcr.io/pichuang/httpbin-re:master
docker run -p 8080:80 ghcr.io/pichuang/httpbin-re:master

# or
docker-compose up -d
```

## TLS termination via nginx

Steps below front the app with nginx so you get HTTP on `http://localhost:8080` and HTTPS on `https://localhost:8443`.

1. Generate (or copy in) certificates. A quick self-signed pair looks like:

  ```sh
  mkdir -p nginx/certs
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout nginx/certs/server.key \
    -out nginx/certs/server.crt \
    -subj "/CN=localhost" -days 365
  ```

  Replace the generated files with your trusted certificates when deploying elsewhere.

1. Launch the compose stack (nginx now terminates TLS and proxies to the `re` service):

  ```sh
  docker-compose up -d
  ```

1. Visit `http://localhost:8080` or `https://localhost:8443`. Adjust the published ports in `docker-compose.yml` if you need to bind directly to 80/443.

See [httpbin.org](http://httpbin.org) for more information.

## Major Changelog

- Change
  - Ubuntu 18.04 -> Ubuntu 22.04
  - Travis CI -> GitHub Actions
  - Python 3.6 -> Python 3.10
  - Pipenv -> built-in pip
- Add
  - Provide variables to change TITLE and DESCRIPTION
  - Follow OCI Specification

## References

- [httpbin](http://httpbin.org)

## SEE ALSO

- [requestb.in](http://requestb.in)
- [python-requests.org](http://python-requests.org)
- [grpcb.in](https://grpcb.in/)
