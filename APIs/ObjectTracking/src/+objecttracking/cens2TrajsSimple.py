import sys
import scipy
from scipy.io import savemat
import numpy as np
import pandas as pd
from pandas import DataFrame, Series  # for convenience
import pims
import trackpy as tp
import os

##The script expects three arguments to be passed: arg1 = dataMat, arg2 = cutOffDist, arg3 = memoryWindow
##dataMat is a matrix of 'x', 'y', 'z', 'mass', 'frame'
##cutOffDist is the neighborhood in pixels that the script will search to link objects between frames
##memoryWindow is the number of frames an object can be missed consecutively before no longer being considered part of the same trajectory


def mat2py2mat(dataMat, cutOffDist, memoryWindow):
	##File info and import

	##Generate pandas dataFrame
	dataMat = (np.asarray(dataMat))
	cutOffDist = int(cutOffDist)
	memoryWindow = int(memoryWindow)
	objDim = dataMat.shape
	if objDim[1] == 5:
		formatDF = pd.DataFrame(dataMat, columns=['x', 'y', 'z','mass','frame'])
		##Calculate trajectories using trackpy
		trajs = tp.link_df(formatDF, cutOffDist, memory=memoryWindow, pos_columns  = ['x','y','z'])
	elif objDim[1] == 4:
		formatDF = pd.DataFrame(dataMat, columns=['x', 'y','mass','frame'])
		##Calculate trajectories using trackpy
		trajs = tp.link_df(formatDF, cutOffDist, memory=memoryWindow, pos_columns  = ['x','y'])

	##Prepare mat file for MATLab Processing
	objInds = (trajs.index).to_numpy()
	trajs['Object Indices'] = objInds
	trajData = trajs.to_numpy()

	##Convert to 1 indexing for IDs
	trajData[:,5:7] = trajData[:,5:7] + 1
	# matlabDict = {"Trajectories": trajData}

	##pyrunfile(file input) executes the Python statements with input arguments. Python scripts read command-line arguments as strings.
	return trajData

trajData = mat2py2mat(dataMat, cutOffDist, memoryWindow)
