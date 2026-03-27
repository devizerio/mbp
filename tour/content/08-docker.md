# Docker

**Containerized development environments.**

Docker Desktop is installed. You can run containers, build images, and
use Docker Compose for multi-service development environments.

## Starting Docker

Docker Desktop runs as a menu bar app. Start it from Applications, or:

  open -a Docker

Wait for the whale icon to appear in the menu bar — that means the
daemon is running.

## Verify it's working

  docker --version
  docker run hello-world

## Common workflows

  docker ps                      — running containers
  docker images                  — local images
  docker compose up              — start a project (from docker-compose.yml)
  docker compose down            — stop and remove containers
  docker system prune            — reclaim disk space

## Development patterns

  docker compose up -d db redis  — start just the backing services
  docker exec -it <id> bash      — shell into a running container
  docker logs -f <id>            — tail container logs

## Per-client containers

Each client project can have its own `docker-compose.yml` with isolated
networks and volumes. Name your services with the client prefix to avoid
conflicts across projects.

## Resource limits

Docker Desktop lets you configure CPU and memory limits in preferences.
For laptop development, 4 CPUs and 8GB RAM is a reasonable starting point.
