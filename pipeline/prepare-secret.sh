#!/bin/bash

# The default token UUID is for US South
TOKEN_UUID=${CR_TOKEN_UUID:-5a611fd2-87d9-5662-8218-30eaba26610b}

CR_TOKEN=$(ibmcloud cr token-get $TOKEN_UUID -q)
sed -e 's/__CR_TOKEN__/'"$CR_TOKEN"'/g' cr-secret.yaml.template > cr-secret.yaml
