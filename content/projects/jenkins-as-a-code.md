---
title: "Building a Modern CI/CD Setup: Jenkins on Docker with Configuration as Code"
subtitle: "How to automate your entire Jenkins configuration — from infrastructure to pipelines — using Docker and JCasC"
date: 2026-02-19
draft: false
topics: ["Software Development"]
description: "Managing Jenkins configuration manually is error-prone, hard to reproduce, and painful to scale. This article walks through a fully containerized Jenkins setup using Docker Compose and the Configuration as Code plugin — so your entire CI/CD infrastructure lives in version control and rebuilds from scratch with a single command"
tags: []
categories: ["projects"]
author: "Marco Castellari"
showToc: true
TocOpen: false
hidemeta: false
comments: false
disableShare: true
hideSummary: false
searchHidden: false
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
cover:
    image: ""
    alt: ""
    caption: ""
    relative: false
    hidden: false
params:
    github: ""
    demo: ""
    tech_stack: []
    status: "in-progress"
---

# Building a Modern CI/CD Setup: Jenkins on Docker with Configuration as Code
If you've ever set up a Jenkins server from scratch, you know the pain: clicking through endless configuration screens, manually installing plugins, setting up users and permissions, and then... hoping you never have to do it again. But what happens when you need to recreate your setup? Or when you want to share your configuration with your team? That's where **Jenkins Configuration as Code** (JCasC) comes in.

In this post, I'll walk you through a fully containerized Jenkins infrastructure that leverages Docker Compose and JCasC to create a reproducible, version-controlled CI/CD environment. This isn't just theory—this is a battle-tested setup I use for building everything from traditional C/C++ applications to embedded STM32 firmware.

## Jenkins Configuration as Code (JCasC)
The solution is treating your Jenkins setup like you treat your application code: **version controlled, reproducible, and automated**.

With Jenkins Configuration as Code, your entire Jenkins configuration lives in YAML files. Combined with Docker, you can spin up a complete, pre-configured Jenkins environment with a single command. No clicking, no manual steps, no "it works on my machine" syndrome.

## Architecture Overview
The proposed setup consists of an orchestrator, that manage the pipeline, and various agents, where the build process happen. 

All components run in Docker containers and communicate over a dedicated bridge network. The agents automatically register themselves with the Jenkins server using the Swarm plugin—no manual node configuration needed.

### 1. Jenkins Server (Orchestrator)
The brain of the operation, running the latest Jenkins LTS with:
- All plugins pre-installed
- Users and permissions configured
- Jobs defined via Job DSL
- GitHub integration ready to go
- Web interface on `localhost:8080`

### 2. GCC Build Agent
A specialized agent for building traditional applications:
- GCC/G++ compiler toolchain
- Build tools (Make, CMake, Ninja)

### 3. STM32 Embedded Agent
A specialized agent for embedded development:
- ARM GNU Toolchain for Cortex-M processors
- STM32-specific programming tools
- Build tools (CMake, Ninja)


## Key Benefits of This Approach
1. **Zero-click setup**

    Just one command to create the Jenkins environment
    ```bash
    docker-compose up -d
    ```
2.  **Version Control Everything**

    The entire infrastructure is defined as code and under version control:
    - `docker-compose.yml` - orchestration
    - `jenkins-casc.yaml` - Jenkins configuration
    - `plugins.txt` - plugin list
    - `Dockerfile` - custom images

3. **Reproducible Environments**

    Clone the repo and run `docker-compose up`.

4. **Isolated Build Environments**

    Each agent runs in its own container with specific tools installed. Your STM32 builds don't interfere with your GCC builds. Everything is clean and isolated.

5. **Easy Customization**

    To add a new plugin edit `plugins.txt` and rebuild.


## How It Works: The Magic Behind the Scenes
### Configuration as Code
The heart of the setup is the `jenkins-casc.yaml` file. This single file defines:
- The authentication strategy with password and secrets stored in `.env` and referenced via variables like `${JENKINS_ADMIN_PASSWORD}`, e.g.
    ```bash
    JENKINS_ADMIN_PASSWORD=your-secure-password
    JENKINS_DEVELOPER_PASSWORD=another-secure-password
    JENKINS_VIEWER_PASSWORD=yet-another-secure-password
    ```

    ```yaml
    jenkins:
    systemMessage: "Jenkins configured automatically by Jenkins Configuration as Code plugin"

    # Security Realm for user authentication
    securityRealm:
        local:
        allowsSignup: false
        users:
            - id: "admin"
            password: "${JENKINS_ADMIN_PASSWORD}"

            - id: "developer"
            password: "${JENKINS_DEVELOPER_PASSWORD}"

            - id: "viewer"
            password: "${JENKINS_VIEWER_PASSWORD}"

    # Authorization Strategy
    authorizationStrategy:
        projectMatrix:
        entries:
            - user:
                name: admin
                permissions:
                - Overall/Administer
            - user:
                name: developer
                permissions:
                - Overall/Read
                - Job/Build
                - Job/Create
                - Job/Delete
                - Job/Configure
                - Job/Workspace
            - user:
                name: viewer
                permissions:
                - Overall/Read

    # Credentials Configuration
    credentials:
    system:
        domainCredentials:
        - credentials:
            - string:
                id: "github-pat"
                description: "GitHub Personal Access Token"
                secret: "${GITHUB_PAT}"
            - usernamePassword:
                id: "github-user-pat"
                description: "GitHub Username and PAT"
                username: "${GITHUB_USERNAME}"
                password: "${GITHUB_PAT}"
    ```

- pipeline job configuration. To create a new pipline simpy add it as a new `script` bullet

    ```yaml
    # Pipeline Job Configuration - All pipelines reference Jenkinsfile from repositories
    jobs:
    - script: |
        try {
            pipelineJob('my-project-pipeline-configuration') {
            description('my-project build pipeline based on Docker agent')
            definition {
                cpsScm {
                scm {
                    git {
                    remote {
                        url('https://github.com/<my-github>/<my-project>.git')
                        credentials('github-user-pat')
                    }
                    branch('*/main')
                    }
                }
                scriptPath('Jenkinsfile')
                }
            }
            triggers {
                githubPush()
            }
            properties {
                githubProjectUrl('https://github.com/<my-github>/<my-project>.git')
            }
            }
        } catch (Exception e) {
            println "Failed to create job: ${e.message}"
        }
    ```

### Docker Compose
The Docker Compose file defines a Jenkins infrastructure made up of an orchestrator and build agents for GCC and STM32 targets.

Each agent connects to the server automatically using the Jenkins Swarm plugin, self-registering with a specific label,  `gcc` or `stm32`,  so pipelines can target the right toolchain by simply declaring 
`agent { label 'stm32' }` in their Jenkinsfile.

All services share a dedicated bridge network, use named volumes to persist workspaces and Jenkins state.

```yaml
services:
  # jenkins-server-orchestrator
  server:
    build: 
      context: ./jenkins-server
      dockerfile: Dockerfile
    container_name: orchestrator
    restart: unless-stopped
    ports:
      - "8080:8080"     # Jenkins web interface
      - "50000:50000"   # Jenkins agent communication
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock 
      - ./jenkins-server/jenkins-casc.yaml:/var/jenkins_home/jenkins-casc.yaml:ro 
    networks:
      - jenkins-network
    environment:
      - CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins-casc.yaml
      - DOCKER_HOST=unix:///var/run/docker.sock
      - JENKINS_OPTS=--httpPort=8080
      # Security: Pass password environment variables to Jenkins
      - JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD}
      - JENKINS_DEVELOPER_PASSWORD=${JENKINS_DEVELOPER_PASSWORD}
      - JENKINS_VIEWER_PASSWORD=${JENKINS_VIEWER_PASSWORD}
      # GitHub Integration
      - GITHUB_PAT=${GITHUB_PAT}
      - GITHUB_USERNAME=${GITHUB_USERNAME}

  # jenkins-server-agent-stm32
  agent-stm32:
      build:
      context: ./agent-stm32
      dockerfile: Dockerfile
      container_name: agent-stm32
      restart: unless-stopped
      privileged: true
      volumes:
      - agent_stm32_workspace:/home/jenkins/agent
      - /var/run/docker.sock:/var/run/docker.sock
      networks:
      - jenkins-network
      command: >
      -master http://server:8080
      -username admin
      -password ${JENKINS_ADMIN_PASSWORD}
      -name docker-agent-stm32
      -labels "docker stm32"
      -executors 2
      -fsroot /home/jenkins/agent
      -disableSslVerification
      environment:
      - ARM_TOOLCHAIN_PATH=/opt/arm-toolchain/bin
      depends_on:
      server:
          condition: service_healthy
```

## Launch Everything
Run the command:
```bash
docker-compose up -d
```

Docker Compose will:
1. Build the Jenkins server image with all plugins
2. Build agents images with their toolchains
3. Start all services with networking configured
4. Start agents that auto-register with the server

## Access and Use
Open `http://localhost:8080` and log in with your configured credentials. You'll find:
- Pre-configured sample jobs
- Agents listed under Manage Jenkins → Nodes
- GitHub integration ready to use


## Customization and Extension
The JCasC approach is really easy it is to customize:

- **Adding Plugins**

    Edit `jenkins-server/plugins.txt`, then rebuild and restart:

    ```text
    my-awesome-plugin:1.2.3
    another-plugin:2.0.0
    ```

- **Adding Tools to Agents**

    Edit the appropriate Dockerfile, then rebuild and restart:

    ```dockerfile
    RUN apt-get update && apt-get install -y \
        your-additional-tool \
        another-tool
    ```

- **Adding New Agents**

    Create a new agent directory, create the Dockerfile for your needs, and add it to `docker-compose.yml`. The Swarm plugin handles the rest.


## Project Pipelines Example
Create a dedicated `Jenkinsfile` foreach project to build and version it with the project

- **Jenkins file for STM32 project**

    ```groovy
    pipeline {
        agent {
            label 'stm32'
        }

        stages {
            stage('Checkout') {
                steps {
                    checkout scm
                }
            }
            
            stage('Configure') {
                steps {
                    sh '''
                        cmake -B ${WORKSPACE}/build/stm32 \
                            -S ${WORKSPACE}
                    '''
                }
            }

            stage('Build') {
                steps {
                    sh '''
                        cmake --build ${WORKSPACE}/build/stm32 \
                            --target example-STM32F103C8T6 \
                            -j$(nproc)
                    '''
                }
            }
        }
        
        post {
            always {
                echo 'Cleaning up workspace...'
                sh 'rm -rf build/obj build/tmp || true'
            }
            
            success {
                echo 'STM32 firmware build completed successfully!'
            }
            
        }
    }
    ```

## Future Enhancements
Some ideas I'm considering:

- INtegrate tests in the pipeline
- Integrate with cloud storage for artifact archival
- Implement automated backup of Jenkins volumes

## Conclusion
In modern software development, your CI/CD infrastructure is just as important as your application code. It should be:

- **Reproducible**: Anyone on the team can recreate it
- **Version controlled**: Changes are tracked and reviewable
- **Automated**: No manual steps means no human error
- **Documented**: The code IS the documentation

This Jenkins-on-Docker setup with Configuration as Code achieves all of these goals and make possible to treat your CI/CD infrastructure like any other piece of software: version-controlled, reproducible, and automated.