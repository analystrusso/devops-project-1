# devops-project-1
This project will serve as an intermission in KodeKloud's 100 Days of DevOps. I've finished the Linux, Git, Docker, and Kubernetes tasks, but before I move on to Jenkins, Terraform, and Ansible, I want to build something. So far, I installed Docker on Linux Mint and made a VERY basic docker-compose.yml file:

```
version: '2.4'
services:
  apache:
    image: httpd:latest
    container_name: project_app
    ports:
    - '8080:80'
    volumes:
    - ./website:/usr/local/apache2/htdocs
```

This sets up an Apache web server to serve files from the /website directory on port 80, as follows:

```
 <!DOCTYPE html>
<html>
<body>

<h1>My First Heading</h1>
<p>My first paragraph.</p>

</body>
</html> 
```

I installed minikube and kubernetes, and used kompose to convert the docker compose file to valid yaml for kubernetes:

apache-deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    kompose.cmd: kompose convert
    kompose.version: 1.34.0 (cbf2835db)
  labels:
    io.kompose.service: apache
  name: apache
spec:
  replicas: 1
  selector:
    matchLabels:
      io.kompose.service: apache
  strategy:
    type: Recreate
  template:
    metadata:
      annotations:
        kompose.cmd: kompose convert
        kompose.version: 1.34.0 (cbf2835db)
      labels:
        io.kompose.service: apache
    spec:
      containers:
        - image: httpd:latest
          name: project-app
          ports:
            - containerPort: 80
              protocol: TCP
          volumeMounts:
            - mountPath: /usr/local/apache2/htdocs
              name: apache-cm0
      restartPolicy: Always
      volumes:
        - configMap:
            name: apache-cm0
          name: apache-cm0
```

apache-service.yaml
```
apiVersion: v1
kind: Service
metadata:
  annotations:
    kompose.cmd: kompose convert
    kompose.version: 1.34.0 (cbf2835db)
  labels:
    io.kompose.service: apache
  name: apache
spec:
  type: NodePort
  ports:
    - name: "8080"
      port: 8080
      targetPort: 80
      nodePort: 30080
  selector:
    io.kompose.service: apache
```

apache-configmap.yaml
```
apiVersion: v1
data:
  index.html: " <!DOCTYPE html>\n<html>\n<body>\n\n<h1>My First Heading</h1>\n<p>My first paragraph.</p>\n\n</body>\n</html> \n"
kind: ConfigMap
metadata:
  labels:
    io.kompose.service: apache
  name: apache-cm0
```


This project will grow over time to demonstrate increasing subject mastery.

