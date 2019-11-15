#!/bin/bash
./dind.sh && make init_k8s && make join && ./kind.sh
