Use Hospital_Py
go
ALTER PROCEDURE [dbo].[score] @model_name varchar(20), 
						 @inquery varchar(max),
						 @output varchar(max)

AS 
BEGIN

	--	Get the trained model, the current database name and the column information.
	DECLARE @model varbinary(max) = (select model from [dbo].[Models] where model_name = @model_name);
	DECLARE @database_name varchar(max) = db_name();
	DECLARE @info varbinary(max) = (select * from [dbo].[ColInfo]);
	-- Compute the predictions. 
	EXECUTE sp_execute_external_script @language = N'Python',
     					               @script = N' 
import dill
from revoscalepy import RxSqlServerData, rx_predict, rx_data_step
##########################################################################################################################################
##	Define the connection string
##########################################################################################################################################
connection_string = "Driver=SQL Server;Server=localhost;Database=" + database_name + ";Trusted_Connection=true;"

##########################################################################################################################################
##	Get the column information.
##########################################################################################################################################
column_info = dill.loads(info)

##########################################################################################################################################
## Point to the data set to score and use the column_info list to specify the types of the features.
##########################################################################################################################################
LoS_Test = RxSqlServerData(sql_query = "{}".format(inquery),
							connection_string = connection_string,
							column_info = column_info)

##########################################################################################################################################
## Random forest scoring.
##########################################################################################################################################
# The prediction results are directly written to a SQL table. 
if model_name == "RF" and len(model) > 0:
	model = dill.loads(model)

	forest_prediction_sql = RxSqlServerData(table = output, connection_string = connection_string, strings_as_factors = True)

	rx_predict(model,
			 data = LoS_Test,
			 output_data = forest_prediction_sql,
			 type = "response",
			 extra_vars_to_write = ["lengthofstay", "ClaimClaimID"],
			 overwrite = True)

##########################################################################################################################################
## Boosted tree scoring.
##########################################################################################################################################
# The prediction results are directly written to a SQL table.
if model_name == "GBT" and len(model) > 0:
	model = dill.loads(model)

	boosted_prediction_sql = RxSqlServerData(table = output, connection_string = connection_string, strings_as_factors = True)

	rx_predict(model,
			data = LoS_Test,
			output_data = boosted_prediction_sql,
			extra_vars_to_write = ["lengthofstay", "ClaimClaimID"],
			overwrite = True)
			
##########################################################################################################################################
## Fast tree scoring.
##########################################################################################################################################
# The prediction results are directly written to a SQL table.
if model_name == "FT" and len(model) > 0:
	from microsoftml import rx_predict as ml_predict
	model = dill.loads(model)

	fast_prediction_sql = RxSqlServerData(table = output, connection_string = connection_string, strings_as_factors = True)

	fast_prediction = ml_predict(model,
			data = LoS_Test,
			extra_vars_to_write = ["lengthofstay", "ClaimClaimID"])

	rx_data_step(input_data=fast_prediction, output_file=fast_prediction_sql, overwrite=True)

##########################################################################################################################################
## Neural network scoring.
##########################################################################################################################################
# The prediction results are directly written to a SQL table.
if model_name == "NN" and len(model) > 0:
	from microsoftml import rx_predict as ml_predict
	model = dill.loads(model)

	NN_prediction_sql = RxSqlServerData(table = output, connection_string = connection_string, strings_as_factors = True)

	NN_prediction = ml_predict(model,
			data = LoS_Test,
			extra_vars_to_write = ["lengthofstay", "ClaimClaimID"])

	rx_data_step(input_data=NN_prediction, output_file=NN_prediction_sql, overwrite=True)  
'
, @params = N' @model_name varchar(20), @model varbinary(max), @inquery nvarchar(max), @database_name varchar(max), @info varbinary(max), @output varchar(max)'	  
, @model_name = @model_name
, @model = @model
, @inquery = @inquery
, @database_name = @database_name
, @info = @info
, @output = @output 
;
END
GO
