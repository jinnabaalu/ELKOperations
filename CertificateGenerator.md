# 🛡️ Elasticsearch Certs Generator

We use [elasticsearch-certutil](https://www.elastic.co/docs/reference/elasticsearch/command-line-tools/certutil) for creating the certificates. This script auto-generates X-Pack-compatible SSL certificates for Elasticsearch nodes using Docker or Podman.

## 📦 Prerequisites
- Docker or Podman
- `unzip`
- `tree`(optional) for output view

## 🤖 What generate-xpack-certs.sh Does
| Step | Action |
|---|---|
|✅ | Prompts for Elasticsearch version and container runtime |
| 🔍 | Detects existing instances.yml or instances.yaml |
| 📄 | Lets you reuse or regenerate node config interactively |
| 🧠 | Supports dynamic cluster sizing (1, 3, or custom) |
| ✍️ | Creates valid instances.yml for cert generation |
| 🔐 | Uses elasticsearch-certutil to generate: `ca.crt`, `ca.key`, and `*.crt`, `*.key` for each node |
| 🧽 | Cleans up old certs and sets secure file permissions |

## 🚀 Download & Execute
```bash
chmod +x generate-certs.sh
./generate-certs.sh
```

> You can generate the `instances.yml` before execution to skips all the following prompts to generate the file. 

## 🧩 Skip Prompts with Predefined Config
You can generate the instances.yml file beforehand to skip the interactive prompts and go straight to cert generation.

Here's a sample:

```
cat <<EOF > instances.yml
instances:
  - name: es01
    ip:
      - 127.0.0.1
    dns:
      - es01
      - localhost
      - test123.jinna.com
  - name: es02
    ip:
      - 127.0.0.1
    dns:
      - es02
      - localhost
  - name: es03
    ip:
      - 127.0.0.1
    dns:
      - es03
      - localhost
  - name: es04
    ip:
      - 12.23.12.1
      - 127.0.0.1
    dns:
      - es04
      - localhost
      - test.jinna.com
  - name: es05
    ip:
      - 127.0.0.1
    dns:
      - es05
      - localhost
      - test1.jinna.com
EOF
```

## ✅ Output Location
All generated certs will be in: /config/certs/
```bash
cd $(pwd)/config/certs/
ls
```

## 🧪 Usage Example
This is a sample config for Elasticsearch node `es01`.
You can **copy the respective cert files/folders** to the target server where the node will run.
```yml
services:
  es01:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: es01
    volumes:
      - $(pwd)/config/certs:/usr/share/elasticsearch/config/certs
    environment:
      ...
      - xpack.security.http.ssl.key=certs/es01/es01.key
      - xpack.security.http.ssl.certificate=certs/es01/es01.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.key=certs/es01/es01.key
      - xpack.security.transport.ssl.certificate=certs/es01/es01.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      ...
```