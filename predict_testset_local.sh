#! /bin/bash


########################################################################
## Input parsing
########################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"	
testset_dir=$1
output_dir=$2

if [ $# -lt 1 ]; then												
		echo $0: "usage: "$( basename $0 )" <test_set_dir> [<output_dir>]"
		return 1;		    
fi 

########################################################################
## Functions
########################################################################
exists () {
                                      			
		if [ $# -lt 1 ]; then
		    echo $0: "usage: exists <filename> "
		    echo "    echo 1 if the file (or folder) exists, 0 otherwise"
		    return 1;		    
		fi 
		
		if [ -d "${1}" ]; then 

			echo 1;
		else
			([ -e "${1}" ] && [ -f "${1}" ]) && { echo 1; } || { echo 0; }	
		fi		
		};

array_mean ()	{

		        if [ $# -lt 1 ]; then														
			    echo $0: "usage: array_mean <array_values>"
			    echo "    array_values: values of the array "
			    echo "    example: array_mean \${array[@]} "	 	
			    return 1;		    
			fi 

			local array=("$@")					
			local val=0
			local N=${#array[@]}
			local mean=0
			for (( i=0; i<$N; i++ )); do
					val=${array[$i]}
	  				mean=$(echo "scale=4; ${mean}+${val} " | bc | awk '{printf "%f", $0}')
			done
			mean=$(echo "scale=4; ${mean}/${N} " | bc | awk '{printf "%f", $0}')

			echo $mean

		};

array_stdev () {
    
			if [ $# -lt 1 ]; then							# usage dello script							
			    echo $0: usage: "array_stdev <vect>"
			    return 1;		    
			fi 

			local vect=("$@")
			mean=$( array_mean ${vect[@]} )
			sqdif=0
			for ((i=0; i<${#vect[@]}; i++)); do  
				sqdif=$(echo "scale=6; ${sqdif}+((${vect[i]}-${mean})^2) " | bc )
			done
			result=$(echo "scale=6; sqrt(${sqdif}/${#vect[@]}) " | bc | awk '{printf "%f", $0}' ) 
			echo $result
	
		}


########################################################################
## Main
########################################################################


predict_script=${SCRIPT_DIR}/"main_local.sh"
disce_score_script=${SCRIPT_DIR}/"dice_score_local.sh"
[ -z ${output_dir} ] && { output_dir=${testset_dir}'/bids/derivatives/bl_app_dbb_DisSeg/' ; }
mkdir -p ${output_dir}
for i in $( ls ${testset_dir}/* -d ); do
	b_name_i=$( basename ${i} )
	[ "${b_name_i}" == "bids" ] && { continue; }
	[ -d ${i} ] || { continue; }
	echo ${i}
	t1_i=$( ls ${i}'/dt-neuro-anat-t1w.id-'*/'t1.nii.gz' )
	mask_i=$( ls ${i}'/dt-neuro-mask.id-'*/'mask.nii.gz' )
	parc_i=$( ls ${i}'/dt-neuro-parcellation-volume.id-'*/'parc.nii.gz' )
	echo 't1': ${t1_i}
	echo 'mask': ${mask_i}
	echo 'parc': ${parc_i}
	output_dir_i=${output_dir}'/'$( basename ${i}  )'/'
	echo ${output_dir_i}
	mkdir -p ${output_dir_i}
	output_seg=${output_dir_i}'/segmentation.nii.gz'	
	[ $( exists $output_seg ) -eq 0 ] && { bash ${predict_script} ${t1_i} ${mask_i} ${output_dir_i}'/' ; }	\
									 || { echo "Brain tissue segmentation already done for "${b_name_i} ;}
	dice_score=${output_dir_i}'/dice_score.txt'
	bash ${disce_score_script} ${output_seg} ${parc_i} ${dice_score}
	cat ${dice_score}
done

csv_file=${output_dir}'/dice_score.csv'
csv_file_average=${output_dir}'/dice_score_average.csv'

echo "Subject_Id CSF GM WM DGM Brainstem Cerebellum"

echo "Subject_Id CSF GM WM DGM Brainstem Cerebellum" > ${csv_file}
idx=0
for i in $( ls ${output_dir}/* -d ); do
	idx=$(( $idx + 1 ))
	echo $( basename ${i} ) $( cat ${i}'/dice_score.txt' )
	dice_score_v=( $( cat ${i}'/dice_score.txt' ) )
	CSF_ds[$idx]=${dice_score_v[0]}
	GM_ds[$idx]=${dice_score_v[1]}
	WM_ds[$idx]=${dice_score_v[2]}
	DGM_ds[$idx]=${dice_score_v[3]}
	BS_ds[$idx]=${dice_score_v[4]}
	Cereb_ds[$idx]=${dice_score_v[5]}
	dss=$( cat ${i}'/dice_score.txt' )
	echo $( basename ${i} ),${dss//' '/','}  >> ${csv_file}

done

CSF_mean=$( array_mean ${CSF_ds[@]} )
GM_mean=$( array_mean ${GM_ds[@]} )
WM_mean=$( array_mean ${WM_ds[@]} )
DGM_mean=$( array_mean ${DGM_ds[@]} )
BS_mean=$( array_mean ${BS_ds[@]} )
Cereb_mean=$( array_mean ${Cereb_ds[@]} )
echo >> ${csv_file}
echo Average,${CSF_mean},${GM_mean},${WM_mean},${DGM_mean},${BS_mean},${Cereb_mean} >> ${csv_file}



CSF_stdev=$( array_stdev ${CSF_ds[@]} )
GM_stdev=$( array_stdev ${GM_ds[@]} )
WM_stdev=$( array_stdev ${WM_ds[@]} )
DGM_stdev=$( array_stdev ${DGM_ds[@]} )
BS_stdev=$( array_stdev ${BS_ds[@]} )
Cereb_stdev=$( array_stdev ${Cereb_ds[@]} )
echo >> ${csv_file}
echo STD,${CSF_stdev} ${GM_stdev} ${WM_stdev} ${DGM_stdev} ${BS_stdev} ${Cereb_stdev} >> ${csv_file}

echo  ${CSF_mean} "("${CSF_stdev}")",${GM_mean}  "("${GM_stdev}")",${WM_mean} "("${WM_stdev}")",${DGM_mean} "("${DGM_stdev}")",${BS_mean} "("${BS_stdev}")",${Cereb_mean} "("${Cereb_stdev}")" > ${csv_file_average}
