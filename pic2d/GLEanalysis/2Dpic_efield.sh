#! /bin/bash
#
# Copyright 2010-2015 CERN and Helsinki Institute of Physics.
# This software is distributed under the terms of the
# GNU General Public License version 3 (GPL Version 3),
# copied verbatim in the file LICENCE.md. In applying this
# license, CERN does not waive the privileges and immunities granted to it
# by virtue of its status as an Intergovernmental Organization
# or submit itself to any jurisdiction.
#
# Project website: http://arcpic.web.cern.ch/
# Developers: Helga Timko, Kyrre Sjobak, Lotta Mether
#

if [ "$#" -ne 4 ] ; then
    echo "Usage: 2Dpic_efield.sh <mintime> <maxtime> <plotting step in um> <every nth frame to analyse>" > /dev/stderr
    echo "Generates joint movies of 2D E-field for 2D Arc-PIC code. " > /dev/stderr
    echo "Run in folder run_name/gle " > /dev/stderr
    echo "Eg. to analyse all frames: 2Dpic_efield.sh 10 200010 1"
    exit
fi

min=$1
max=$2
pstep=$3
nth=$4

step1=`head -2 ../out/timeIndex.dat | tail -1 | awk '{print $1}'`
step2=`head -3 ../out/timeIndex.dat | tail -1 | awk '{print $1}'`
step=`echo | awk -v step1=$step1 -v step2=$step2 -v nth=$nth '{ printf "%d", step2-step1*nth}'`
code=`echo | awk -v m=$min '{ printf "%08ld", m}'`

echo "Starting code is $code"
echo "Timestep is $step"


### RESCALING DATA TO DIMENSIONAL VALUES ###

ne=`grep "Reference density in 1/cm3:" ../input.txt | awk '{print $5}'`
Te=`grep "Reference temperature in eV:" ../input.txt | awk '{print $5}'`
nr=`grep "Number of cells nr, nz:" ../input.txt | awk '{print $6}'`
nz=`grep "Number of cells nr, nz:" ../input.txt | awk '{print $7}'`
dz=`grep "Grid size dz in Debyes:" ../input.txt | awk '{print $6}'`
dt=`grep "Timestep dt in Omega_pe-s:" ../input.txt | awk '{print $5}'`
dt_out=`grep "Outputting time dt_out in O_pe-s:" ../input.txt | awk '{print $6}'`

echo "Parameters"
echo "ne= $ne Te= $Te"
echo "nr= $nr nz= $nz"
echo "dz= $dz dt= $dt"
echo "dt_out= $dt_out"

### *** ###



# WRITING CORRECT FIT INTO GLE
echo | awk -v nz=$nz -v nr=$nr -v dz=$dz -v n=$ne -v Te=$Te '{Ld=sqrt(552635*Te/n); del=dz*Ld*10000; Lz=nz*dz*Ld*10000; Lr=nr*dz*Ld*10000; printf"%2.2f %2.1f %2.1f \n",del,Lz,Lr;}' > grid.tmp

del=`head -1 grid.tmp | awk '{print $1}'`
Lz=`head -1 grid.tmp | awk '{print $2}'`
Lr=`head -1 grid.tmp | awk '{print $3}'`
echo "For fitting: del= $del Lz= $Lz Lr= $Lr"

eval "sed -e '/ xz/ c\x from 0 to $Lr step $pstep ' <efield.gle >efield_tmp1.gle "
eval "sed -e '/ yz/ c\y from 0 to $Lz step $pstep ' <efield_tmp1.gle >efield_tmp2.gle "
eval "sed -e '/ xr/ c\x from 0 to $Lr step $pstep ' <efield_tmp2.gle >efield_tmp3.gle "
eval "sed -e '/ yr/ c\y from 0 to $Lz step $pstep ' <efield_tmp3.gle >efield_grid.gle "
rm efield_tmp*.gle grid.tmp


# PRINT OUT TIME (in ns)
rm time.dat
cat ../out/timeIndex.dat | awk -v dt=$dt -v ne=$ne '{omega=56414.6*sqrt(ne); t=$1; time=t*dt*1e+9/omega; printf "%08ld %1.2f \n", t, time}' > time.dat 

rm -r pngs/efield
mkdir pngs/efield



k=1
for ((i=$min; i<=$max; i=i+$step)); do

  now_is=`grep "$code" time.dat | awk '{print $2}'`
  echo "now_is $now_is"
  echo "code is $code"


### EFIELD ###
    rm ez.dat er.dat

    # create temporary file with rescaled values, output in GV/m
    cat ../out/Ez${code}.dat | awk -v n=$ne -v Te=$Te '{ Ld=sqrt(552635*Te/n); r=$1; z=$2; ez=$3; r=r*Ld*10000; z=z*Ld*10000; ez=ez*1e-7*Te/Ld; {printf "%.4f %.4f %.6e \n", r,z,ez;}}' > ez.dat	
    cat ../out/Er${code}.dat | awk -v n=$ne -v Te=$Te '{ Ld=sqrt(552635*Te/n); r=$1; z=$2; er=$3; r=r*Ld*10000; z=z*Ld*10000; er=er*1e-7*Te/Ld; {printf "%.4f %.4f %.6e \n", r,z,er;}}' > er.dat


    # execute gle, into png or jpg format
    eval "sed -e '/Time/ c\write \"Time $now_is ns\" ' <efield_grid.gle >efield_tmp.gle "

    # HIGH RESOLUTION/LOW RESOLUTION
    #   gle -d png -dpi 300 -o joint${k} joint_tmp.gle
    kk=`echo | awk -v k=$k '{ printf "%03ld", k}'`
    gle -d png -o efield${kk} efield_tmp.gle
    mv efield${kk}.png pngs/efield/.

    rm efield_tmp.gle

  k=`echo $(($k+1))`
  code=`echo | awk -v i=$i -v s=$step '{x=i+s; printf "%08ld", x;}'`
  echo " "
		


done
#rm ez.dat er.dat ez.z er.z efield_grid.gle

ffmpeg -sameq -r 20 -f image2 -i pngs/efield/efield%03d.png  pngs/efield/movie_efield.mpg

echo "Done with analysis!"
