#start=`date +%s`
for((i=1;i<10000;i++))
do
   #echo "the $i time to query"
   start=`date +%s`
   curl  "10.254.171.132:8980/sas?cmd=login&username=admin&password=password" 
   echo "\n"
   end=`date +%s`
   dif=$[ end - start ]
   echo $dif
   echo "login $i success."
done
#end=`date +%s`
#dif=$[ end - start ]
#echo $dif
