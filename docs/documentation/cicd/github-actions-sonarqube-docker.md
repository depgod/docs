# GitHub Actions: SonarQube Scanning & Docker Image Deployment to Harbor

## Overview

!!! info "Guide Information"
    **Difficulty**: Intermediate  
    **Time Required**: ~30 minutes for setup  
    **Last Updated**: March 2025  
    **GitHub Actions Version**: Latest  
    **SonarQube Version**: 9.9 LTS or newer  
    **Harbor Version**: 2.8+

This guide provides comprehensive instructions for setting up a GitHub Actions workflow that:

1. Scans your code using SonarQube for quality and security issues
2. Builds a Docker image from your codebase
3. Pushes the image to a private Harbor registry

The workflow is designed to work with private repositories and includes environment variable handling, secrets management, and comprehensive error handling.

## Prerequisites

Before you begin, ensure you have:

- A GitHub account with a private repository containing your application code
- Admin access to a SonarQube instance (self-hosted or SonarCloud)
- Access to a Harbor registry instance
- A Dockerfile in your repository that defines your application image
- Basic understanding of YAML and GitHub Actions concepts

## Repository Structure

For this workflow to function correctly, your repository should be structured similar to:

```
your-repository/
├── .github/
│   └── workflows/
│       └── build-scan-deploy.yml  # Our GitHub Actions workflow file
├── src/                           # Your application source code
├── Dockerfile                     # Instructions to build your Docker image
├── sonar-project.properties       # SonarQube configuration (optional)
└── README.md
```

!!! tip "Repository Organization"
    While this is a suggested structure, the workflow can be adapted to different repository layouts. Just ensure the paths in the workflow file match your actual structure.

## Step-by-Step Implementation

### 1. Create GitHub Secrets

First, you'll need to add the following secrets to your GitHub repository:

1. Navigate to your GitHub repository
2. Go to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret** and add the following:

| Secret Name | Description |
|-------------|-------------|
| `SONAR_TOKEN` | Authentication token for SonarQube |
| `SONAR_HOST_URL` | URL of your SonarQube instance (not needed for SonarCloud) |
| `HARBOR_USERNAME` | Username for Harbor registry |
| `HARBOR_PASSWORD` | Password or access token for Harbor registry |
| `HARBOR_URL` | URL of your Harbor registry (e.g., `harbor.example.com`) |
| `HARBOR_PROJECT` | Project name in Harbor where images will be stored |

### 2. Create the GitHub Actions Workflow File

Create a new file at `.github/workflows/build-scan-deploy.yml` with the following content:

```yaml
name: Build, Scan and Deploy

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
  # Allow manual triggering
  workflow_dispatch:

env:
  # Default environment variables
  IMAGE_NAME: my-application
  IMAGE_TAG: ${{ github.sha }}
  # You can add more environment variables here

jobs:
  code-quality:
    name: Code Quality Scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          # Fetch all history for better SonarQube analysis
          fetch-depth: 0

      - name: SonarQube Scan
        uses: SonarSource/sonarqube-scan-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
        with:
          # Additional arguments for the sonarqube scanner
          args: >
            -Dsonar.projectKey=${{ github.repository_owner }}_${{ github.event.repository.name }}
            -Dsonar.projectName=${{ github.repository_owner }}_${{ github.event.repository.name }}

      # Optional: Fail the pipeline if quality gate fails
      - name: SonarQube Quality Gate
        uses: SonarSource/sonarqube-quality-gate-action@master
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}

  build-and-push:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest
    # Only run if code quality passes or if we're on main/master branch
    needs: code-quality
    if: success() || github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master'
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Harbor
        uses: docker/login-action@v3
        with:
          registry: ${{ secrets.HARBOR_URL }}
          username: ${{ secrets.HARBOR_USERNAME }}
          password: ${{ secrets.HARBOR_PASSWORD }}

      # Generate image tags based on git information
      - name: Generate Image Tags
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ secrets.HARBOR_URL }}/${{ secrets.HARBOR_PROJECT }}/${{ env.IMAGE_NAME }}
          tags: |
            type=raw,value=latest,enable=${{ github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master' }}
            type=sha,format=short
            type=ref,event=branch
            type=ref,event=tag
            type=semver,pattern={{version}}

      # Build and push the image
      - name: Build and Push Docker Image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ secrets.HARBOR_URL }}/${{ secrets.HARBOR_PROJECT }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ secrets.HARBOR_URL }}/${{ secrets.HARBOR_PROJECT }}/${{ env.IMAGE_NAME }}:buildcache,mode=max
          build-args: |
            BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
            VCS_REF=${{ github.sha }}
            VERSION=${{ steps.meta.outputs.version }}

      # Optional: Scan the built image for vulnerabilities
      - name: Scan Docker Image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ secrets.HARBOR_URL }}/${{ secrets.HARBOR_PROJECT }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'CRITICAL,HIGH'
```

### 3. Configure SonarQube Properties (Optional)

If you need custom SonarQube configuration, create a `sonar-project.properties` file in the root of your repository:

```properties
# Project identification
sonar.projectKey=your-project-key
sonar.projectName=Your Project Name
sonar.projectVersion=1.0

# Source code location
sonar.sources=src
sonar.tests=tests

# Encoding of the source files
sonar.sourceEncoding=UTF-8

# Exclude patterns
sonar.exclusions=**/node_modules/**,**/*.spec.ts,**/dist/**,**/coverage/**

# Coverage reports path (if you have test coverage)
sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

### 4. Create or Update Your Dockerfile

Ensure your Dockerfile is optimized for security and efficiency:

```dockerfile
# Use specific version for reproducible builds
FROM node:18-alpine AS build

# Create app directory
WORKDIR /app

# Install dependencies first (better caching)
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production image
FROM node:18-alpine AS production

# Set non-root user for security
USER node
WORKDIR /app

# Copy only production dependencies and built app
COPY --from=build --chown=node:node /app/package*.json ./
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist

# Set environment variables
ENV NODE_ENV=production

# Expose port
EXPOSE 3000

# Start the application
CMD ["node", "dist/main.js"]
```

## How It Works

### Workflow Breakdown

1. **Code Quality Scan**:
   - Checks out your code
   - Runs SonarQube analysis to identify code quality issues
   - Optionally fails the pipeline if quality gate fails

2. **Build and Push**:
   - Builds a Docker image using your Dockerfile
   - Tags the image with appropriate version information
   - Pushes the image to your Harbor registry
   - Scans the built image for security vulnerabilities

### Environment Variables and Secrets

The workflow uses:

- **GitHub Secrets**: For sensitive information like tokens and passwords
- **Environment Variables**: For configuration that might change between runs
- **Dynamic Tagging**: To ensure proper versioning of your Docker images

## Troubleshooting

### Common Issues and Solutions

#### SonarQube Analysis Fails

**Issue**: SonarQube scan fails with authentication errors.

**Solution**:
- Verify your `SONAR_TOKEN` is valid and has not expired
- Ensure the token has appropriate permissions in SonarQube
- Check that your SonarQube instance is accessible from GitHub Actions

#### Docker Build Fails

**Issue**: Docker build fails with errors.

**Solution**:
- Check your Dockerfile for syntax errors
- Ensure all required files are present in the repository
- Verify that build arguments are correctly defined
- Look for network issues if pulling base images

#### Harbor Push Fails

**Issue**: Cannot push to Harbor registry.

**Solution**:
- Verify Harbor credentials are correct
- Ensure the project exists in Harbor
- Check that your user has push permissions to the project
- Verify Harbor URL is correct and includes the protocol (https://)

#### Quality Gate Timeout

**Issue**: SonarQube quality gate check times out.

**Solution**:
- Increase the timeout in the workflow file
- Check if SonarQube is processing a large backlog
- Verify SonarQube server performance

### Debugging Tips

1. **Enable Debug Logging**:
   - Set the secret `ACTIONS_STEP_DEBUG` to `true` in your repository
   - This provides more detailed logs during workflow execution

2. **Manual Workflow Runs**:
   - Use the "workflow_dispatch" trigger to manually run the workflow
   - This helps isolate issues from code changes

3. **Step-by-Step Testing**:
   - Comment out later steps to focus on fixing earlier issues
   - Gradually enable steps as you resolve problems

## Advanced Configuration

### Using Matrix Builds

For testing across multiple environments:

```yaml
jobs:
  build-matrix:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [16.x, 18.x]
        environment: [development, staging]
    steps:
      # ... steps that use matrix variables
      - name: Build with variables
        run: |
          echo "Building for Node ${{ matrix.node-version }} in ${{ matrix.environment }}"
```

### Conditional Workflows

To run different steps based on conditions:

```yaml
steps:
  - name: Run only on main branch
    if: github.ref == 'refs/heads/main'
    run: echo "This runs only on main branch"

  - name: Run only on PRs
    if: github.event_name == 'pull_request'
    run: echo "This runs only on pull requests"
```

### Caching Dependencies

To speed up builds by caching dependencies:

```yaml
- name: Cache Node modules
  uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

## Security Best Practices

1. **Scan Images for Vulnerabilities**:
   - Use Trivy or other scanners to check for CVEs
   - Set appropriate severity thresholds

2. **Use Specific Tags**:
   - Avoid using `latest` tag for production deployments
   - Use immutable tags based on git SHA or semantic versions

3. **Minimize Image Size**:
   - Use multi-stage builds to reduce attack surface
   - Remove development dependencies from production images

4. **Protect Secrets**:
   - Never hardcode secrets in Dockerfiles or workflow files
   - Rotate secrets regularly

5. **Run as Non-Root**:
   - Configure containers to run as non-root users
   - Use the principle of least privilege

## Conclusion

This GitHub Actions workflow provides a robust CI/CD pipeline that ensures code quality through SonarQube scanning and delivers secure, versioned Docker images to your Harbor registry. By following this guide, you've implemented industry best practices for continuous integration and delivery.

For more advanced scenarios or customizations, refer to the official documentation for [GitHub Actions](https://docs.github.com/en/actions), [SonarQube](https://docs.sonarqube.org/), and [Harbor](https://goharbor.io/docs/).

!!! tip "Next Steps"
    Consider integrating this workflow with ArgoCD for continuous deployment to your Kubernetes cluster. See our [ArgoCD Setup Guide](../../argocd-setup.md) for more information.
