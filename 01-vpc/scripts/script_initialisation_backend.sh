#!/bin/bash

docker run -d -p 8000:8000 --name mon-backend --restart unless-stopped iac-backend



