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

## What are Docker Images?

Docker images are immutable, read-only templates that serve as the foundation for creating containers. Think of them as "snapshots" or "blueprints" that contain everything needed to run an application: the code, runtime, system tools, libraries, and settings. Unlike virtual machine images that contain entire operating systems, Docker images are lightweight and share the host OS kernel, making them incredibly efficient for modern application deployment.

## Why Use Docker Images?

- **Environment Differences**: Docker images eliminate "Works on my machine" syndrome

- **Dependency Hell**: Conflicting library versions are resolved through isolation

- **Manual Configuration**: Time-consuming server setup becomes automated

- **Inconsistent Deployments**: Docker ensures identical environments across all stages

- **Scaling Challenges**: Images enable rapid environment replication

- **Immutability**: Images never change, ensuring consistent deployments

- **Portability**: Run anywhere Docker is installed across all platforms

- **Efficiency**: Shared layers reduce storage and bandwidth requirements

- **Version Control**: Tag-based versioning for precise application releases

## Docker Image Architecture

- Docker Registry stores images and manages distribution
- Local Docker Host pulls images with `docker pull` command
- Images consist of multiple _read-only layers_ stacked together
- **Containers** add a _writable layer_ on top of image layers
- Layer structure includes base OS, packages, runtime, dependencies, code, and configuration
- Running containers get writable layers for runtime changes while keeping image layers immutable
- Multiple containers can share the same base image layers for efficiency

## Core Docker Image Concepts

- **Layer Sharing**: Multiple images share common base layers, saving storage
- **Layer Caching**: Unchanged layers are reused, accelerating builds and pulls
- **Copy-on-Write**: Containers get writable layers on top of read-only image layers
- **Layer Inspection**: Use docker history to see all layers and their sizes
- **Image Identification**: By repository and tag, image ID, or digest for precise reference
- **Registry Hierarchy**: Registry contains namespaces, repositories, and tagged versions
- **Version Management**: Use semantic versioning, environment tags, or git-based tags

## Image Lifecycle and Management

- Dockerfile instructions create layers during build process
- Image build combines layers into immutable image
- Image push uploads to registry with specific tag
- Image pull downloads to local machine for use
- Container creation adds writable layer on top of image
- Version management uses semantic versioning, environment tags, or git-based tags
- Storage optimization through minimal base images and multi-stage builds
- Regular cleanup of unused images and layers prevents storage issues

## DockerHub and Registry Operations

- Official Images: Curated, security-scanned base images from Docker

- Community Images: User-contributed images that require careful evaluation

- Private Repositories: Secure storage for proprietary applications

- Automated Builds: Integration with Git repositories for CI/CD workflows

- Webhooks: Automated actions triggered when images are pushed

- Security Scanning: Built-in vulnerability detection for image layers

## Production Image Management Best Practices

- Regularly update base images for security patches

- Use minimal base images to reduce attack surface

- Scan images for vulnerabilities before deployment

- Implement image signing and verification

- Avoid running containers as root user

- Use multi-stage builds to exclude sensitive build tools

- Optimize Dockerfile layer order for better caching

- Use .dockerignore to exclude unnecessary files

- Monitor image sizes and layer counts

## Common Image Management Pitfalls

- Using latest tag in production creates unpredictable deployments
- Large image sizes due to unnecessary layers slow deployments
- Not cleaning up old images leads to disk space exhaustion
- Storing secrets in image layers exposes them in image history
- Ineffective layer caching causes slow builds and wasted resources
- Solutions include pinning specific versions, multi-stage builds, regular cleanup, and proper secret management

## Image Registry Strategies for Different Environments

- Development: Use DockerHub for base images, local registry for team collaboration, frequent builds with dev-specific tags

- Staging: Mirror production setup, automated security scanning, performance testing with staging-specific tags

- Production: Private secured registries, immutable semantic versioning, security scanning, high availability with production tags

- Each environment requires specific registry strategies aligned with security and operational requirements

## Practice

This section walks you through common Docker image management commands using the lightweight `alpine` image as an example. Each step includes a brief explanation.

1. **Search for Docker images related to 'alpine':**

   Use the `docker search` command to find images from Docker Hub that match the keyword `alpine`. This helps you discover official and community-maintained images.

   ```
   sudo docker search alpine
   ```

2. **Pull a specific version of the Alpine image:**

   Download the `alpine:3.18` image from Docker Hub to your local machine. Specifying the tag (`3.18`) ensures you get a known, stable version.

   ```
   sudo docker pull alpine:3.18
   ```

3. **List all local Docker images:**

   View all images currently stored on your system. This helps verify that the `alpine:3.18` image was downloaded successfully.

   ```
   sudo docker images
   ```

4. **Tag the image with a custom name and version:**

   Create a new tag for the pulled image. This is useful for versioning and organizing images, especially before pushing to a private registry.

   ```
   sudo docker tag alpine:3.18 my-alpine:v1
   ```

5. **Inspect the image's metadata:**

   Display detailed information about the image, such as its layers, environment variables, and configuration. This is useful for troubleshooting and auditing.

   ```
   sudo docker inspect my-alpine:v1
   ```

6. **Save the image to a tar archive:**

   Export the image to a tarball file. This is useful for backing up images or transferring them between systems without using a registry.

   ```
   sudo docker save -o alpine.tar my-alpine:v1
   ```

7. **Remove the image from your local Docker storage:**

   Delete the tagged image from your system to free up space or test the image loading process.

   ```
   sudo docker rmi my-alpine:v1
   ```

8. **Load the image back from the tar archive:**

   Import the previously saved image back into your local Docker image store. This restores the image and its tag.

   ```
   sudo docker load -i alpine.tar
   ```

> **Tip:** You can verify the image is restored by running `sudo docker images` again.

These steps cover the basic lifecycle of searching, pulling, tagging, inspecting, saving, removing, and loading Docker images.

## References

- [DevOps Labs](https://www.devopsxlabs.com/labs)
- [How to install in Ubuntu](https://dev.to/coder7475/how-to-install-docker-engine-on-ubuntu-debian-3nbp)
