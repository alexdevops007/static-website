#!/bin/bash

# create a repository to store the docker image in docker hub

# launch an ec2 instance open on port 80 and 22

# install and configure docker on the ec2 instance
sudo yum update -y
sudo amazon-linux-extras install docker
sudo service docker start
sudo systemctl enable docker

# create a dockerfile
sudo docker build -t static-website .

# login to docker hub account
cat ~/my_password.txt | sudo docker login --username alexdevops007 --password-stdin

# use the docker tag command to give the image a new name
sudo docker tag static-website alexdevops007/static-website

# push the image to your docker hub repository
sudo docker push alexdevops007/static-website

# start the container to test the image
sudo docker run -dp 80:80 alexdevops007/static-website

# referances
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-container-image.html
# https://docs.docker.com/get-started/02_our_app/
# https://docs.docker.com/engine/reference/commandline/login/#provide-a-password-using-stdin