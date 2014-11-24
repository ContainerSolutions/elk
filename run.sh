#!/bin/sh
docker run -p 80:80 -p 5000:5000 --name elk -d containersol/elk

