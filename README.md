# devops-project-1
This project will serve as an intermission in KodeKloud's 100 Days of DevOps. I've finished the Linux, Git, Docker, and Kubernetes tasks, but before I move on to Jenkins, Terraform, and Ansible, I want to build something. So far, I installed Docker on Linux Mint and made a VERY basic docker-compose.yml file:

version: '2.4'
services:
  apache:
    image: httpd:latest
    container_name: project_app
    ports:
    - '8080:80'
    volumes:
    - ./website:/usr/local/apache2/htdocs

This sets up an Apache web server to serve files from the /website directory on port 80.
