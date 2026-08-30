#!/bin/bash
# Dynamic Swarm Cron Runner for Catherine Wallage Portfolio
CID=$(docker ps --filter "name=catherine-portfolio_wordpress" --filter "status=running" --format "{{.ID}}" | head -n 1)

if [ -n "$CID" ]; then
    docker exec -u sickchill "$CID" wp cron event run --due-now --quiet > /dev/null 2>&1
fi
