#This script extracts weather-data from the records of the Ventus W831 Weather station
#
#Ver. 1.0 30.06.2011 Martin Patrong Haspang (Program created)
#Ver. 1.1 06.08.2011 Martin Patrong Haspang (Included uploading small size jpg's to the web server to in order to improve accessibility from cell phones)
#Ver. 1.2 07.08.2011 Martin Patrong Haspang (Fixed problems with ugly graphs when server and/or weather station has been turned off)
#Ver. 1.3 05.11.2016 Martin Patrong Haspang (Included channel 2 temperature measurements)

while true; do

mv ../win-share/wca/'Weather Capture Advance'/RECORD1*.txt ../win-share/weather/

for i in `ls ../win-share/weather`; do
if [ "$i" != "" ]; then							#The script is to be executed only if there is (a) datafile(s)
	
	cat -v ../win-share/weather/$i > ./all-data-1.dat		#Print datafile including hidden characters (here: linebreak)
	sed 's/\^M//g' all-data-1.dat > all-data-2.dat			#Remove hidden characters
	sed 's/\^@//g' all-data-2.dat > all-data-2a.dat
	sed 's/M-//g' all-data-2a.dat > all-data-2b.dat
	sed 's/\^//g' all-data-2b.dat > all-data-2c.dat
	sed 's/\?//g' all-data-2c.dat > all-data-2d.dat
	sed 's/\~//g' all-data-2d.dat > all-data-3.dat



	sed 1!d all-data-3.dat > ./time.dat				#Separate datafile into the various parameters
	sed 3!d all-data-3.dat > ./pressure.dat
	sed 8!d all-data-3.dat > ./in-temp-hum.dat
	sed 9!d all-data-3.dat > ./out-temp-hum.dat
	sed 10!d all-data-3.dat > ./chan2-temp-hum.dat
	sed 14!d all-data-3.dat > ./rain.dat
	sed 15!d all-data-3.dat > ./wind-spe-dir.dat
	sed 16!d all-data-3.dat > ./wind-chill-gust.dat

	sed 's/Computer\ Date\ \/\ Time\:\ //g' time.dat > dummy1.dat	#Remove bogus from datafile
	time=`sed 's/\ /\-/g' dummy1.dat`
	if [ "$time" == "" ]; then					#If the weather station has been unplugged, the time variable will sometimes
	time=NaN							#not have a usefull value. In that case, write NaN (Not a Number)
	fi
	if [ "$time" == "0000.00.00-00:00" ]; then
	time=NaN
	fi
	sed 's/\./\ /g' dummy1.dat > dummy2.dat				#Remove bogus
	sed 's/\:/\ /g' dummy2.dat > dummy3.dat
	yyyy=(`cat dummy3.dat|awk '{print $1}'`)			#Assing seperate time-variables for each time unit
	mm=(`cat dummy3.dat|awk '{print $2}'`)
	dd=(`cat dummy3.dat|awk '{print $3}'`)
	hh=(`cat dummy3.dat|awk '{print $4}'`)
	minmin=(`cat dummy3.dat|awk '{print $5}'`)

	pressure=`sed 's/Pressure (mBar\/hPa)\:\ //g' pressure.dat`			#Remove bougs
	if [ "$pressure" == "" ]; then					#If there is no data in this sample, write NaN
	pressure=NaN
	fi

	intemp=`sed -e 's/.*(degC): //' -e 's/ Hum.*$//' in-temp-hum.dat`
	if [ "$intemp" == "" ]; then
	intemp=NaN
	fi

	inhum=`sed -e 's/.*Humidity (\%): //' in-temp-hum.dat`
	if [ "$inhum" == "" ]; then
	inhum=NaN
	fi

	outtemp=`sed -e 's/.*(degC): //' -e 's/ Hum.*$//' out-temp-hum.dat`
	if [ "$outtemp" == "" ]; then
	outtemp=NaN
	fi

	outhum=`sed -e 's/.*Humidity (\%): //' out-temp-hum.dat`
	if [ "$outhum" == "" ]; then
	outhum=NaN
	fi

	chantwotemp=`sed -e 's/.*(degC): //' -e 's/ Hum.*$//' chan2-temp-hum.dat`
	if [ "$chantwotemp" == "" ]; then
	chantwotemp=NaN
	fi

	chantwohum=`sed -e 's/.*Humidity (\%): //' chan2-temp-hum.dat`
	if [ "$chantwohum" == "" ]; then
	chantwohum=NaN
	fi


	rain=`sed -e 's/.*total  (mm): //' rain.dat`
	if [ "$rain" == "" ]; then
	rain=NaN
	fi

	windspeed=`sed -e 's/.*(m\/s): //' -e 's/ Wind Direction.*$//' wind-spe-dir.dat`
	if [ "$windspeed" == "" ]; then
	windspeed=NaN
	fi

	winddir=`sed -e 's/.*Wind Direction: //' wind-spe-dir.dat`
	if [ "$winddir" == "" ]; then
	winddir=NaN
	fi

	windchill=`sed -e 's/.*(degC): //' -e 's/ Wind Gust.*$//' wind-chill-gust.dat`
	if [ "$windchill" == "" ]; then
	windchill=NaN
	fi

	windgust=`sed -e 's/.*Gust (m\/s): //' wind-chill-gust.dat`
	if [ "$windgust" == " " ]; then
	windgust=NaN
	fi

	if [ ! -d "./old-data/$yyyy" ]; then
	mkdir ./old-data/$yyyy
	fi

	if [ ! -d "./old-data/$yyyy/$mm$dd" ]; then
	mkdir ./old-data/$yyyy/$mm$dd
	fi

	if [ ! -f "./old-data/$yyyy/$mm$dd/daily-weather-record.dat" ]; then
	cp ./weather-record-template.dat ./old-data/$yyyy/$mm$dd/daily-weather-record.dat
	fi


	if [ "$hh" == "00" ]; then						#Reset the total rainfall at midnight
	  if [ "$minmin" == "00" ]; then					
	  raininit=$rain
	  elif [ "$minmin" == "01" ]; then
	  raininit=$rain
	  fi
	fi

	echo $rain $raininit > dummy4.dat
	if [ "$rain" == "NaN" ]; then
	rainreset=NaN
	else
	rainreset=`awk '{print $1 - $2}' dummy4.dat`
#	rainreset=`expr $rainreset \+ 522.7` #Se aendring.txt
	fi

########## This section adds lines of continuing time and data parameters NaN. This is helpful if the server and/or the
########## weather station has been shut down because it ensures that the datafiles always contain a number of lines that
########## corresponds to 24 hours.

if [ "$time" != "NaN" ]; then						#Do not run this section the fisrt time the script is run
									#(since the privious time is not known)

j=0
while true; do								#Read the time from the last line in the data file. If this is not a valid number
	j=`expr $j \+ 1`						#(NaN), continue with the second last line and so on.
	tail -$j weather-record.dat > dummy9b.dat
	head -1 dummy9b.dat > dummy9.dat
	timeprev=`cat dummy9.dat|awk '{print $1}'`
	echo $timeprev > dummy10.dat
	if [ "$timeprev" != "NaN" ]; then
	  break
	fi
done

sed "s/\./ /g" dummy10.dat > dummy11.dat					#Grab the different time units separately
sed "s/\-/ /g" dummy11.dat > dummy12.dat
sed "s/\:/ /g" dummy12.dat > dummy13.dat
yyyyprev=(`cat dummy13.dat|awk '{print $1}'`)
mmprev=(`cat dummy13.dat|awk '{print $2}'`)
ddprev=(`cat dummy13.dat|awk '{print $3}'`)
hhprev=(`cat dummy13.dat|awk '{print $4}'`)
minminprev=(`cat dummy13.dat|awk '{print $5}'`)



k=0
while true; do
k=`expr $k \+ 1`
minminprev=`expr $minminprev \+ 1`						#Increase the minutes by 1
if [ "$minminprev" -lt "10" ]; then						#Add a leading 0 to minutes between 0 and 10
  if [ "$minminprev" -gt "0" ]; then
    minminprev=0$minminprev
  fi
fi

if [ "$minminprev" == "60" ]; then
  minminprev=00
  hhprev=`expr $hhprev \+ 1`
  if [ "$hhprev" -lt "10" ]; then
    if [ "$hhprev" -gt "0" ]; then
      hhprev=0$hhprev
    fi
  fi

  if [ "$hhprev" == "24" ]; then
    hhprev=00
    ddprev=`expr $ddprev \+ 1`
    if [ "$ddprev" -lt "10" ]; then
      if [ "$ddprev" -gt "0" ]; then
        ddprev=0$ddprev
      fi
    fi

    case "$mmprev" in								#Increase the month by one, if the date exeeds the number of days in a given month
	01)	if [ "$ddprev" == "32" ]; then
		  ddprev=01
		  mmprev=02
		fi
		;;

	02)	leapa=`expr $yyyyprev \/ 4`					#Take care of leap years. (Only valid until 12.31.2099, since centuries are not
		leapb=`expr $leapa \* 4`					#leap years even though they are a mulitiple of 4)

		if [ "$leapb" == "$yyyyprev" ]; then
		  if [ "$ddprev" == "30" ]; then
		  ddprev=01
		  mmprev=03
		  fi
		else
		  if [ "$ddprev" == "29" ]; then
		  ddprev=01
		  mmprev=03
		  fi
		fi
		;;

	03)	if [ "$ddprev" == "32" ]; then
		  ddprev=01
		  mmprev=04
		fi
		;;

	04)	if [ "$ddprev" == "31" ]; then
		  ddprev=01
		  mmprev=05
		fi
		;;

	05)	if [ "$ddprev" == "32" ]; then
		  ddprev=01
		  mmprev=06
		fi
		;;

	06)	if [ "$ddprev" == "31" ]; then
		  ddprev=01
		  mmprev=07
		fi
		;;

	07)	if [ "$ddprev" == "32" ]; then
		  ddprev=01
		  mmprev=08
		fi
		;;

	08)	if [ "$ddprev" == "32" ]; then
		  ddprev=01
		  mmprev=09
		fi
		;;

	09)	if [ "$ddprev" == "31" ]; then
		  ddprev=01
		  mmprev=10
		fi
		;;

	10)	if [ "$ddprev" == "32" ]; then
		  ddprev=01
		  mmprev=11
		fi
		;;

	11)	if [ "$ddprev" == "31" ]; then
		  ddprev=01
		  mmprev=12
		fi
		;;

	12)	if [ "$ddprev" == "32" ]; then
		  ddprev=01
		  mmprev=01
		  yyyyprev=`expr $yyyyprev \+ 1`
		fi
		;;
    esac
  fi
fi


ka=`expr $k \/ 2`								#Check if k is an even number
kb=`expr $ka \* 2`


if [ "$yyyyprev.$mmprev.$ddprev-$hhprev:$minminprev" != "$time" ]; then		#Write NaN's to datafile until time equals present
  if [ "$kb" == "$k" ]; then							#Only write NaN's to datafile if k is even, that is every second minute
    echo $yyyyprev.$mmprev.$ddprev-$hhprev:$minminprev'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN >> master-weather-record.dat
    echo $yyyyprev.$mmprev.$ddprev-$hhprev:$minminprev'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN >> weather-record.dat
    echo $yyyyprev.$mmprev.$ddprev-$hhprev:$minminprev'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN'  'NaN >> ./old-data/$yyyy/$mm$dd/daily-weather-record.dat
  fi
else
  break
fi	

if [ "$k" -gt "1480" ]; then							#Only write a maximum of 720 lines (more lines are deleted anyway)
break
fi
done

fi

##########
			#The following three lines is the final datafiles. The first stores ALL weather data (Large datafile!)
			#The second stores weather data from the last 24 hours
			#The third datafile stores weather data from each day

	echo $time'  '$pressure'  '$intemp'  '$inhum'  '$outtemp'  '$outhum'  '$chantwotemp'  '$chantwohum'  '$rain'  '$windspeed'  '$winddir'  '$windchill'  '$windgust >> master-weather-record.dat
	echo $time'  '$pressure'  '$intemp'  '$inhum'  '$outtemp'  '$outhum'  '$chantwotemp'  '$chantwohum'  '$rain'  '$windspeed'  '$winddir'  '$windchill'  '$windgust >> weather-record.dat
	echo $time'  '$pressure'  '$intemp'  '$inhum'  '$outtemp'  '$outhum'  '$chantwotemp'  '$chantwohum'  '$rainreset'  '$windspeed'  '$winddir'  '$windchill'  '$windgust >> ./old-data/$yyyy/$mm$dd/daily-weather-record.dat

	mv ../win-share/weather/$i ./old-data/$yyyy/$mm$dd/$i			#Save the original datafiles in an appropriate directory

fi
done

if [ "$i" != "" ]; then								#This is only to be done if there is (a) datafile(s)

	linecount=`sed -n "$=" weather-record.dat`				#Make sure there is weather data from the last 24 hours only
	while true; do
		if [ $linecount -gt 738 ]; then
		sed 18d weather-record.dat > dummy.dat
		linecount=`sed -n "$=" dummy.dat`
		mv dummy.dat weather-record.dat
		else
		break
		fi
	done

	firstline=17
	while true; do
	firstline=`expr $firstline \+ 1`
	sed $firstline!d weather-record.dat > dummy5.dat				#Set the total rainfall at 0.0 mm 24 hours ago
	firstrain=`awk '{print $7}' dummy5.dat`
	if [ "$firstrain" != "NaN" ]; then
	break
	fi
	done

	sed 1,14d weather-record.dat > dummy7.dat				#Read the datafile
	timearray=(`cat dummy7.dat|awk '{print $1}'`)
	presarray=(`cat dummy7.dat|awk '{print $2}'`)
	intemparray=(`cat dummy7.dat|awk '{print $3}'`)
	inhumarray=(`cat dummy7.dat|awk '{print $4}'`)
	outtemparray=(`cat dummy7.dat|awk '{print $5}'`)
	outhumarray=(`cat dummy7.dat|awk '{print $6}'`)

	chantwotemparray=(`cat dummy7.dat|awk '{print $7}'`)
	chantwohumarray=(`cat dummy7.dat|awk '{print $8}'`)

	rainarray=(`cat dummy7.dat|awk '{print $9}'`)
	wspeedarray=(`cat dummy7.dat|awk '{print $10}'`)
	wdirarray=(`cat dummy7.dat|awk '{print $11}'`)
	wchillarray=(`cat dummy7.dat|awk '{print $12}'`)
	wgustarray=(`cat dummy7.dat|awk '{print $13}'`)


	cp weather-record-template.dat weather-record-rainreset.dat	#Use a template for the new datafile

	for ((k=0; k < 720; k++)); do
	echo ${rainarray[$k]}' '$firstrain > dummy6.dat 			#Set the total rainfall at 0.0 mm 24 hours ago
	if [ "${rainarray[$k]}" == "NaN" ]; then
	rainreset2=NaN
	else	
	rainreset2=`awk '{print $1 - $2}' dummy6.dat`
	fi
	echo ${presarray[$k]}' 2.3' > dummy8.dat				#Calibrate the pressure to match that of DMI at Lyngbyvej, Copenhagen.
	if [ "${presarray[$k]}" == "NaN" ]; then				#Calibration constant (6.7) determined in July, 2011
	preskalibrated=NaN
	else	
	preskalibrated=`awk '{print $1 + $2}' dummy8.dat`			
	fi

										#Write a new datafile with calibrated and reset data
	echo ${timearray[$k]}'  '$preskalibrated'  '${intemparray[$k]}'  '${inhumarray[$k]}'  '${outtemparray[$k]}'  '${outhumarray[$k]}'  '${chantwotemparray[$k]}'  '${chantwohumarray[$k]}'  '$rainreset2'  '${wspeedarray[$k]}'  '${wdirarray[$k]}'  '${wchillarray[$k]}'  '${wgustarray[$k]} >> weather-record-rainreset.dat
	done

	rm all-data-1.dat							#Remove temporary files
	rm all-data-2.dat
	rm all-data-2a.dat
	rm all-data-2b.dat
	rm all-data-2c.dat
	rm all-data-2d.dat
	rm all-data-3.dat
	rm dummy1.dat
	rm dummy2.dat
	rm dummy3.dat
	rm dummy4.dat
	rm dummy5.dat
	rm dummy6.dat
	rm dummy7.dat
	rm dummy8.dat
	rm dummy9.dat
	rm dummy9b.dat
	rm dummy10.dat
	rm dummy11.dat
	rm dummy12.dat
	rm dummy13.dat
	rm time.dat
	rm pressure.dat
	rm in-temp-hum.dat
	rm out-temp-hum.dat
	rm rain.dat
	rm wind-spe-dir.dat
	rm wind-chill-gust.dat

	#epstopdf temp.eps							#If Gnuplot is set to generate .eps files, these can be converted 
	#epstopdf wind.eps							#into a single .pdf
	#epstopdf pres.eps
	#epstopdf hum.eps
	#epstopdf rain.eps
	#pdftk temp.pdf wind.pdf pres.pdf hum.pdf rain.pdf output weather.pdf

	gnuplot weather.plt							#Create the graphs using Gnuplot

	for i in `ls *.jpg`; do							#Create small .jpg's for the mobile weather page
	cp $i mobil
		convert mobil/$i -geometry 50%x50% mobil/small-$i
	done

#	scp *.jpg fys.ku.dk:public_html/vejret					#Upload files to web server
#	scp mobil/small*.jpg fys.ku.dk:public_html/vejret/mobil
	date
fi


i=''										#Clear filename variable
sleep 600									#Run script every 10 mins
done

#### TO BE FIXED:

#To execute type: nohub weather.sh						#The program Nohup can be used if the script is executed on a 
#Output is stored in nohub.out							#server from a remote machine. (Not yet functional)
#
#To terminate:
#Type ps aux
#Find PID:
#Example: haalle   19062  0.0  0.0   1912   508 ?        S    19:48   0:00 /bin/sh ./test.sh
#Type: kill 19062
