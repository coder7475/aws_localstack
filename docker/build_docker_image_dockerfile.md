# What are Dockerfiles?

Dockerfiles are text-based scripts containing step-by-step instructions for building Docker images. They serve as the blueprint that transforms a base image into a customized application image. Think of a Dockerfile as a recipe that tells Docker exactly how to package your application with all its dependencies, configurations, and runtime requirements into a portable, immutable image.

---

## Why Use Dockerfiles?

- **Unique Dependencies:** Applications require specific libraries, frameworks, or tools
- **Configuration Requirements:** Custom environment variables, file permissions, startup scripts
- **Security Hardening:** Non-root users, minimal attack surface, secure defaults
- **Build Artifacts:** Compiled code, processed assets, optimized configurations
- **Version Control:** Reproducible builds with exact dependency versions
- **Infrastructure as Code:** Version-controlled, auditable image definitions
- **Reproducible Builds:** Identical images across development, testing, and production
- **Layered Caching:** Fast rebuilds by reusing unchanged layers
- **Automated Processes:** No manual configuration or forgotten setup steps

---

## Dockerfile Build Process Architecture

- **Build Context:** Contains Dockerfile, source code, and configuration files
- **Docker Build Process:** Creates layers for each instruction in sequential order
- **Layer Structure:** `FROM` creates base layer, `RUN`/`COPY` add content, `CMD` defines runtime
- **Final Image:** All layers are read-only, cacheable, and stack from base to application
- **Image Size:** Total size depends on base image and added content, compressed for distribution

---

## Dockerfile Instruction Reference and Best Practices

- **FROM:** Always use specific tags, avoid generic tags like `latest`, choose appropriate base images
- **WORKDIR:** Set consistent working directory, avoid `/root` or `/`, create directory structure as needed
- **COPY vs ADD:** Use `COPY` for simple operations, `ADD` for URLs and auto-extraction, use `.dockerignore` for optimization
- **RUN:** Combine related commands to reduce layers, order matters for caching, clean up package caches
- **ENV and ARG:** Set environment variables for runtime, use `ARG` for build-time variables
- **EXPOSE:** Documents ports but doesn't publish them
- **CMD vs ENTRYPOINT:** `CMD` can be overridden, `ENTRYPOINT` is fixed, combine for flexibility

---

## Multi-Stage Build Patterns

- Separate build and runtime environments for smaller production images
- Development stage includes dev tools, production stage includes only runtime dependencies
- Language-specific patterns optimize for different technology stacks

---

## Build Context Optimization

- Build context includes all files in the directory where `docker build` runs
- Large contexts slow builds and waste bandwidth
- Use `.dockerignore` to exclude unnecessary files like `node_modules`, `.git`, logs
- Optimize build context patterns for faster, more secure builds

---

## Security Best Practices

- Create and use non-root users for improved security
- Never store secrets in image layers – use build secrets or runtime injection
- Minimize attack surface by using minimal base images and removing unnecessary packages
- Implement proper user management and file permissions

---

## Build Performance and Optimization

- Layer caching strategies improve build speed by reusing unchanged layers
- Order instructions from least to most frequently changing
- Use BuildKit advanced features for parallel builds and better caching
- Monitor and optimize image sizes and build times

---

## Common Dockerfile Antipatterns

- Large image sizes from unnecessary layers and files
- Secrets exposed in image layers through build history
- Running containers as root user creates security vulnerabilities
- Poor layer caching due to incorrect instruction ordering

**Solutions include multi-stage builds, proper secret management, and user configuration.**

Lab: https://www.devopsxlabs.com/labs
