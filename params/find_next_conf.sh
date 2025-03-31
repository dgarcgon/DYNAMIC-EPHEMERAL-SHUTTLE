#!/bin/bash
 
DIR="params/"
string_a_buscar="VAR_TEMPLATE_PROJECT_CODE_LOWERCASE"

echo $DIR

FS='
'
for item in $(ls $DIR)
do
        encontrado=$(grep $string_a_buscar $DIR/$item | cut -b 1-7)
        if [[ $encontrado == 'PROJECT' ]]; then
        sed -i 's/'$string_a_buscar'/'$1'/g' $item
        mv $DIR/$item $DIR/$1_params.env
        echo $item
        exit
        fi
done
