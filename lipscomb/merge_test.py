import pandas as pd

#Create Test Data Sets
# df1 = pd.DataFrame({'StudentID': ['A1','A2','A7'],
# 					'B': ['B1','B2','B3'],
# 					'C': ['C1','C2','C3'],
# 					})

# df2 = pd.DataFrame({'B': ['B3','B4','B5','B0','B6'],
# 					'StudentID': ['A1','A2','A2','A5','A7'],
# 					'C': ['C1','C3','C4','C0','C5'],
# 					})




def merge_data(df1,df2,identifier_string):
	#Merge Two Data Sets to Indicate which individuals show up in the new data set
	dfMerge = df1.merge(df2,how='left',on=identifier_string,indicator=True)

	#Reshape this merged file to include all individuals who have an observation in the new data set 
	newData1 = dfMerge[dfMerge.columns[0:(len(df1.columns))]]
	newData2 = pd.concat([dfMerge[identifier_string],dfMerge[dfMerge.columns[(len(df1.columns)):len(dfMerge.columns)-1]]],axis=1)

	#Put Student ID on first
	cols = newData1.columns.tolist()
	cols = [cols[-1]]+cols[:-1] # or whatever change you need
	newData1 = newData1.reindex(columns=cols)

	newData1.columns = range(newData1.shape[1])
	newData2.columns = range(newData2.shape[1])

	newData3 = newData1.append(newData2)

	#Gives all individuals who have an observation in the new data set
	finalNewEntries = newData3.drop_duplicates()

	#Gives old + new data
	fullData = df1.append(df2)
	cols = fullData.columns.tolist()
	cols = [cols[-1]]+cols[:-1] # or whatever change you need
	fullData = fullData.reindex(columns=cols)

	finalNewEntries.columns = fullData.columns

	#Gives all individuals in the old data which don't have an observation in the new data
	finalOldEntries = pd.concat([fullData,finalNewEntries]).drop_duplicates(keep=False)
	finalOldEntries.columns = fullData.columns

	#Generates variable 'newflag'
	finalOldEntries['newflag'] = 0
	finalNewEntries['newflag'] = 1

	#Generates final data with 'newflag'
	FinalData = pd.concat([finalNewEntries,finalOldEntries])

	#Prints out data
	return(FinalData)

df1 = pd.read_csv('/users/mwolff/desktop/Lipscomb.csv').dropna(how='all')
df2 = pd.read_csv('/users/mwolff/desktop/Lipscomb_old.csv').dropna(how='all')


data = merge_data(df1,df2,'StudentID')

print(data)




