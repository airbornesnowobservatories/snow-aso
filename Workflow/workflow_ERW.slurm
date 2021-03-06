#!/bin/bash

#SBATCH --job-name=ERW_snow_depth
#SBATCH --account=owner-gpu-guest
#SBATCH --partition=notchpeak-gpu-guest

#SBATCH --time=4:00:00
#SBATCH --ntasks=2
#SBATCH --mem=12G

#SBATCH --mail-type=FAIL
#SBATCH --mail-user=student@utah.edu

#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

##-------##
# Set Up  #
##-------##

PROJECT_HOME=${HOME}/projects/ERW_2018
SCRATCH_HOME=${HOME}/scratch

source load_conda_env snow_aso

cd ${SCRATCH_HOME}

SNOW_ON=ERW_20180524
SNOW_FREE=ERW_20180912
PC_ALIGN_SUFFIX=trans_source.laz

##-----------##
# Classifier  #
##-----------##
ASO_SNOW_ON=${SCRATCH_HOME}/${SNOW_ON}/Lidar/
LIDAR_CLASSIFIED=${ASO_SNOW_ON}/${SNOW_ON}_cropped_classified.laz

##
# pdal pipeline ${PROJECT_HOME}/classifier/1_classify_cloud.json \
#   --readers.las.filename=${ASO_SNOW_ON}/${SNOW_ON}_merge.laz \
#   --filters.colorization.raster=${SCRATCH_HOME}/${SNOW_ON}/CASI/ERW_20180524_casi_classified.tif \
#   --writers.las.filename=${LIDAR_CLASSIFIED}

##
# pdal pipeline ${PROJECT_HOME}/classifier/2_create_NoR_geotiff.json \
#   --readers.las.filename=${LIDAR_CLASSIFIED} \
#   --writers.gdal.filename=${ASO_SNOW_ON}/${SNOW_ON}_NoR_1m.tif

##
# pdal pipeline ${PROJECT_HOME}/classifier/3_create_stable_geotiff.json \
#   --readers.las.filename=${LIDAR_CLASSIFIED} \
#   --writers.gdal.filename=${ASO_SNOW_ON}/${SNOW_ON}_stable_dem_1m.tif

##------------------##
# ASO Reference DEM  #
##------------------##

# pdal pipeline ${PROJECT_HOME}/co-registration/4R_create_geotiff.json \
#   --readers.las.filename=${LIDAR_CLASSIFIED} \
#   --writers.gdal.filename=${ASO_SNOW_ON}/${SNOW_ON}_dsm_3m.tif

##------------##
# Co-Register  #
##------------##
REFERENCE_CLOUD=${ASO_SNOW_ON}/${SNOW_ON}_reference.laz

##
# pdal pipeline ${PROJECT_HOME}/co-registration/1L_prepare_fixed_cloud.json \
#   --readers.las.filename=${LIDAR_CLASSIFIED} \
#   --filters.colorization.raster=${SCRATCH_HOME}/${SNOW_ON}/Stable-Ground/${SNOW_ON}_NoR_FS_no_snow_1m.tif \
#   --writers.las.filename=${REFERENCE_CLOUD}

##------------##
# Snow-On      #
#  Co-Register #
##------------##
SFM_SNOW_ON=${SCRATCH_HOME}/${SNOW_ON}/Agisoft

##
# pdal pipeline ${PROJECT_HOME}/co-registration/2A_create_moving_cloud.json \
#   --readers.las.filename=${SFM_SNOW_ON}/${SNOW_ON}.laz \
#   --writers.las.filename=${SFM_SNOW_ON}/${SNOW_ON}_moving.laz

##
# ${PROJECT_HOME}/co-registration/3_pc_align.sh \
#   ${SFM_SNOW_ON}/pc_align/snow_on \
#   ${REFERENCE_CLOUD} \
#   ${SFM_SNOW_ON}/${SNOW_ON}_moving.laz

##
# pdal pipeline ${PROJECT_HOME}/co-registration/4M_create_geotiff.json \
#   --readers.las.filename=${SFM_SNOW_ON}/pc_align/snow_on-${PC_ALIGN_SUFFIX} \
#   --writers.gdal.filename=${SFM_SNOW_ON}/${SNOW_ON}_dsm_1m.tif

##
# gdalwarp --optfile ${PROJECT_HOME}/process-helpers/resample_3m_cut.gdal \
#   ${SFM_SNOW_ON}/${SNOW_ON}_dsm_1m.tif \
#   ${SFM_SNOW_ON}/${SNOW_ON}_ERW_basin_dsm_3m.tif

##------------##
# Snow-Free    #
#  Co-Register #
##------------##
SFM_SNOW_FREE=${SCRATCH_HOME}/${SNOW_FREE}/Agisoft

##
# pdal pipeline ${PROJECT_HOME}/co-registration/2A_create_moving_cloud.json \
#   --readers.las.filename=${SFM_SNOW_FREE}/${SNOW_FREE}.laz \
#   --writers.las.filename=${SFM_SNOW_FREE}/${SNOW_FREE}_moving.laz

##
# ${PROJECT_HOME}/co-registration/3_pc_align.sh \
#   ${SFM_SNOW_FREE}/pc_align/snow_free \
#   ${REFERENCE_CLOUD} \
#   ${SFM_SNOW_FREE}/${SNOW_FREE}_moving.laz

##
# pdal pipeline ${PROJECT_HOME}/co-registration/4M_create_geotiff.json \
#   --readers.las.filename=${SFM_SNOW_FREE}/pc_align/snow_free-${PC_ALIGN_SUFFIX} \
#   --writers.gdal.filename=${SFM_SNOW_FREE}/${SNOW_FREE}_dsm_1m.tif

##
# gdalwarp --optfile ${PROJECT_HOME}/process-helpers/resample_3m_cut.gdal \
#   ${SFM_SNOW_FREE}/${SNOW_FREE}_dsm_1m.tif \
#   ${SFM_SNOW_FREE}/${SNOW_FREE}_ERW_basin_dsm_3m.tif

##-----------##
# Snow Depth  #
##-----------##

# mkdir -p ${SCRATCH_HOME}/snow_depth
# cd ${SCRATCH_HOME}/snow_depth

##
# gdalbuildvrt -b 3 \
#   ${SNOW_ON}_ERW_basin_dsm_3m_band3.vrt \
#   ${SFM_SNOW_ON}/${SNOW_ON}_ERW_basin_dsm_3m.tif

# gdalbuildvrt -b 3 \
#   ${SNOW_FREE}_ERW_basin_dsm_3m_band3.vrt \
#   ${SFM_SNOW_FREE}/${SNOW_FREE}_ERW_basin_dsm_3m.tif

# ${PROJECT_HOME}/process-helper/geo_diff.sh \
#   ${SNOW_ON}_ERW_basin_dsm_3m_band3.vrt \
#   ${SNOW_FREE}_ERW_basin_dsm_3m_band3.vrt

# cd ${SCRATCH_HOME}

##------------------##
# ASO Snow free DEM  #
##------------------##
ASO_SNOW_FREE=${SCRATCH_HOME}/${SNOW_FREE}/Lidar

##
# pdal pipeline ${PROJECT_HOME}/aso-reference/ASO_create_moving_cloud.json \
#   --readers.las.filename=${ASO_SNOW_FREE}/${SNOW_FREE}_merge.laz \
#   --writers.las.filename=${ASO_SNOW_FREE}/${SNOW_FREE}_moving.laz

##
# ${PROJECT_HOME}/co-registration/3_pc_align.sh \
#   ${ASO_SNOW_FREE}/pc_align/snow_free \
#   ${REFERENCE_CLOUD} \
#   ${ASO_SNOW_FREE}/${SNOW_FREE}_moving.laz

##
# pdal pipeline ${PROJECT_HOME}/aso-reference/last_only_cloud.json \
#   --readers.las.filename=${ASO_SNOW_FREE}/${SNOW_FREE}_merge.laz \
#   --writers.las.filename=${ASO_SNOW_FREE}/${SNOW_FREE}_last_only.laz

##
# ${PROJECT_HOME}/aso-reference/apply_transform.sh \
#   ${ASO_SNOW_FREE}/pc_align/snow_free-transform.txt \
#   ${ASO_SNOW_FREE}/pc_align_transform/snow_free \
#   ${REFERENCE_CLOUD} \
#   ${ASO_SNOW_FREE}/${SNOW_FREE}_last_only.laz

##
# pdal pipeline ${PROJECT_HOME}/aso-reference/ASO_geotiff.json \
#   --readers.las.filename=${ASO_SNOW_FREE}/pc_align_transform/snow_free-${PC_ALIGN_SUFFIX} \
#   --writers.gdal.filename=${ASO_SNOW_FREE}/${SNOW_FREE}_Lidar_dsm_3.tif
