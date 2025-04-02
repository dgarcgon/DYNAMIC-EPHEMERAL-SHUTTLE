#!/bin/bash

DIR="params"
string_a_buscar="VAR_TEMPLATE_PROJECT_CODE_LOWERCASE"
  
if [[ $1 == 'in' ]]; then
FS='
'
for item in $(ls $DIR)
do
        encontrado=$(grep $string_a_buscar $DIR/$item | cut -b 1-7)
        if [[ $encontrado == 'PROJECT' ]]; then
        sed -i 's/'$string_a_buscar'/'$2'/g' $DIR/$item
        mv $DIR/$item $DIR/$2_params.env
        echo $item
        exit
        fi
done
fi
 
 
if [[ $1 == 'out' ]]; then 
FS='
'
for item in $(ls $DIR)
do
file_name="${item##*/}"
file_code=${file_name/_params.env/""}
           if [[ $2 == $file_code ]]; then
           codigo=$(cat $DIR/$item | grep FILE_ID | cut -b 9-10)
           restored_file_name=$codigo"_params.env"
           sed -i 's/'$2'/'$string_a_buscar'/g' $DIR/$item
           mv $DIR/$item $DIR/$restored_file_name
           echo $item "restored to" $restored_file_name
           fi
done
fi
