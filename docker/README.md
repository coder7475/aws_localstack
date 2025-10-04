## What is the Docker CLI?

The Docker Command Line Interface (CLI) is your primary tool for interacting with Docker. It's a powerful interface that allows you to manage containers, images, networks, volumes, and more through simple commands. Think of it as the remote control for Docker - every Docker operation can be performed through CLI commands.

## Why Use the Docker CLI?

- Automation: Scripts and CI/CD pipelines rely on CLI commands

- Precision: Exact control over Docker operations with specific flags and options

- Debugging: Direct access to container internals for troubleshooting

- Efficiency: Faster than GUI tools once you learn the commands

- Universal: Works the same across all operating systems and environments

- Documentation: CLI commands are self-documenting with built-in help

## Key Docker CLI Concepts

- **Container Lifecycle Commands**: `docker run` creates and starts new containers, `docker start/stop/restart` control existing containers, `docker rm` removes containers

- **Image Management Commands**: `docker pull` downloads images, `docker images` lists local images, `docker rmi` removes images, `docker tag` creates new tags

- **Information and Inspection**: `docker ps` lists containers, `docker logs` shows output, `docker inspect` provides detailed information, `docker exec` runs commands inside containers

## Container Execution Modes

- **Interactive Mode (-it)**: Connects your terminal to the container's terminal for debugging and exploration

- **Detached Mode (-d)**: Container runs in the background, ideal for services like web servers

- **Port Mapping (-p)**: Maps container ports to host ports using format host_port:container_port

## Docker CLI Best Practices

- Always use specific image tags instead of latest in production

- Clean up regularly with `docker system prune` to save disk space

- Use meaningful container names with --name flag for easier management

- Check container logs when troubleshooting with docker logs container_name

- Use docker exec instead of SSH to access running containers

- Understand the difference between docker run (create + start) and docker start (start existing)

## Common Pitfalls and How to Avoid Them

- Using docker run repeatedly instead of docker start creates multiple containers instead of reusing existing ones

- Not cleaning up stopped containers and unused images causes disk space to fill up quickly

- Running containers without proper port mapping prevents access to services inside containers

- Not using container names makes containers hard to identify and manage

## Real-World CLI Usage Scenarios

- Development Workflow: Pull images, run with volume mounts for live development, check logs for debugging, execute commands inside containers

- Production Deployment: Pull specific versions, run with resource limits and restart policies, monitor container health and performance

### How to test your knowledge

By mastering these CLI fundamentals, you'll have the foundation for all advanced Docker operations. Complete the practice steps below and then validate your lab to ensure you've learned the essential Docker CLI commands.

## References

- [DevOps Labs](https://www.devopsxlabs.com/labs)
- [How to install in Ubuntu](https://dev.to/coder7475/how-to-install-docker-engine-on-ubuntu-debian-3nbp)
