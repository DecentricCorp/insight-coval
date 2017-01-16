#!/bin/sh
    DIR="$( cd "$( dirname "$0" )" && pwd )"
    


    if [ -n "$1" ]; then
        namespace=$1
        if [ -n "$2" ]; then
        deploytype=$2

        #----- Create instance on Bluemix
        function build() {
            cf ic build -t registry.ng.bluemix.net/$namespace/coval-explorer . --no-cache
        }

        function startSingle(){
            cf ic run -p 3027:3027 -m 2048 --name coval-explorer registry.ng.bluemix.net/$namespace/coval-explorer
        }
        function single(){
            build
            echo "Deploying a "$deploytype" instance to Bluemix"
            startSingle
        }       

        function group() {
            build
            echo "Deploying a "$deploytype" instance to Bluemix"
            echo "Starting Bluemix Volume handling"
            fs=`cf ic volume fs-list | grep legacyledgerfix`
            if [ -n "$fs" ]; then
                echo "found fs legacyledgerfix"
            else 
                echo "didn't find fs legacyledgerfix"
                fscreate=`cf ic volume fs-create legacyledgerfix 20 4`
                echo $fscreate
                ready=`cf ic volume fs-inspect legacyledgerfix | grep READY`
                while [ -z "$ready" ]
                do
                    echo $ready "fs being built. Pausing 5s"
                    sleep 5
                    ready=`cf ic volume fs-inspect legacyledgerfix | grep READY`
                done
                    echo "complete"
            fi

            share=`cf ic volume list | grep legacyledgershare`
            if [ -n "$share" ]; then
                echo "found volume legacyledgershare"
            else 
                echo "didn't find volume legacyledgershare"
                create=`cf ic volume create legacyledgershare legacyledgerfix`
                echo $create
            fi            
            cf ic group create --name coval-explorer \
                        --publish 3027 --memory 2048 --auto \
                        --hostname coval-explorer \
                        --domain mybluemix.net \
                        --min 1 --max 2 --desired 1 \
                        --volume legacyledgershare:/root/.coval-insight \
                        registry.ng.bluemix.net/$1/coval-explorer
        }

        

        [ "$deploytype" == "single" ] && single
        [ "$deploytype" == "group" ] && group
        [ "$deploytype" == "startsingle" ] && startSingle
        
    else 
        echo "Please specify a deploy type (local | group | single)"
    fi
else
    echo "Please provide the namespace or name for this deployment"
fi