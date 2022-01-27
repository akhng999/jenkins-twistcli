#Dockerfile
FROM  python:3.8-slim-buster

#Install NGINX
RUN apt-get update && apt-get install nginx -y --no-install-recommends
RUN apt-get upgrade libwebp6 -y
COPY nginx.default /etc/nginx/sites-available/default

RUN mkdir /VulnerableWebApp
COPY . /VulnerableWebApp
 
WORKDIR /VulnerableWebApp/VulnerableWebApp

RUN pip install -r requirements.txt

EXPOSE 8080
CMD ["./startup.sh"]
