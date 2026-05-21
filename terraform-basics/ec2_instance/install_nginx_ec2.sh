#!/bin/bash


sudo apt-get update -y
sudo apt-get install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

echo "<h1> Hi this is Deepak webpage installed on ec2 using terraform </hi>"  | sudo tee /var/www/html/index.html