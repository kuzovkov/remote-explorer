#!/bin/bash

###############################
# Showis docker networks      #
###############################


for network in $(docker network ls --format "{{.Name}}"); do
    subnets=$(docker network inspect $network | jq -r '.[] | .IPAM.Config[] | .Subnet')

    echo "$network:"
    if [ -z "$subnets" ]; then
        echo -e "\tNo containers"
    else
        while IFS= read -r line
        do
            echo -e "\t$line"
        done <<< "$subnets"
    fi
done
