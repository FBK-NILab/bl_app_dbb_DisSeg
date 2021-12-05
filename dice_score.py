#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Thu Oct  7 16:10:08 2021

@author: gamorosino
"""


import argparse
import numpy as np
from UnetBrainSeg import dice_score
import os
#%% Main

if __name__ == '__main__':
    
    ## Parsing Inputs
    parser = argparse.ArgumentParser(description='Estimate Metrics')
    parser.add_argument('fullpath', metavar='predicted', type=str, nargs='+',
                        help='fullpath of predicted segmentation')
    parser.add_argument('fullpath1', metavar='ground truth', type=str, nargs='+',
                        help='fullpath of ground truth')
    parser.add_argument('fullpath2', metavar='output file', type=str, nargs='+',
                        help='fullpath of ouput file')
    #parser.add_argument('fullpath2', metavar='checkpoints_dir', type=str, nargs='+',
    #                    help='fullpath of checkpoints directories')   
    
    args = parser.parse_args()
    predicted_file=args.fullpath[0]    
    gtruth_file=args.fullpath1[0]     
    output_file=args.fullpath2[0] 
    #outputfile=args.fullpath1[0]
    #checkpoints_dir=args.fullpath2[0]

    dice_score=dice_score(predicted_file,gtruth_file ,seg_labels=None)

    os.system("echo "+''.join(list(dice_score))+" > "+output_file)

                           
