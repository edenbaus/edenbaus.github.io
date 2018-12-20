#!/usr/bin/env bash

#The purpose of this script is to compose all csv files in a given google cloud storage bucket

GSINPUT=$1
FILENAME=$2


Green='\033[0;92m'
Blue='\033[0;94m'
NC='\033[0m'
COUNT=1
gssize=2

gscompose () {
gsinput=$1
iter=$2
filename=$3

gsarrary=(`gsutil ls "${gsinput}"/"${filename}"*.csv`) #gather input files to bash array
gssize="${#gsarray[@]}" #get number of files in array

a="$((gssize/30))" # integer division by 30 to find number of full composes needed
b="$((gssize%30))" # mod 30 to find if 1 more compose is necessary

if [ $b -gt 0 ]
then
  a=$((a+1))
fi

echo -e "${Blue}Compose loop started${NC}"

for i in `seq 1 $a`; do
    st=$((1+($i-1)*30))
    ed=$(($st+30))
    echo "gsutil compose ${gsarray[@]:$st:$ed} ${gsinput}/${filename}-${iter}-${i}.csv"
done

echo -e "${Green}Compose loop finished${NC}"
}

# Loop gscompose function on results in recursive fashion until GSINPUT has a single file

#initialize gssize = 2 to ensure first compose starts
while [ ${gssize} -gt 1 ]
do
echo -e "${Blue}Compose # ${COUNT}${NC}"

gscompose ${GSINPUT} ${COUNT} ${FILENAME}
COUNT=$((COUNT+1))
done
