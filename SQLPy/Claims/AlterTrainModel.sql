use Hospital_Py
go
ALTER PROCEDURE [dbo].[train_model]   @model_name varchar(20),
								 @dataset_name varchar(max) 
AS 
BEGIN
	-- Create an empty table to be filled with the trained models.
	IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Models' AND xtype = 'U')
	CREATE TABLE [dbo].[Models](
		[model_name] [varchar](30) NOT NULL default('default model'),
		[model] [varbinary](max) NOT NULL
		)

	-- Get the database name and the column information. 
	DECLARE @info varbinary(max) = (select * from [dbo].[ColInfo]);
	DECLARE @database_name varchar(max) = db_name();

	-- Train the model on the training set.	

    select 1 from models where model_name = 'RF'
	DELETE FROM Models WHERE model_name = @model_name;
	INSERT INTO Models (model)
	EXECUTE sp_execute_external_script @language = N'Python',
									   @script = N' 
import dill
from numpy import sqrt
from pandas import DataFrame
from revoscalepy import RxInSqlServer, rx_set_compute_context, RxSqlServerData, rx_dforest, rx_btrees
from microsoftml import rx_fast_trees, rx_neural_network, adadelta_optimizer
##########################################################################################################################################
##	Set the compute context to SQL for faster training
##########################################################################################################################################
# Define the connection string
connection_string = "Driver=SQL Server;Server=localhost;Database=" + database_name + ";Trusted_Connection=true;"

# Set the Compute Context to SQL.
sql = RxInSqlServer(connection_string = connection_string)
rx_set_compute_context(sql)

##########################################################################################################################################
##	Get the column information.
##########################################################################################################################################
column_info = dill.loads(info)

##########################################################################################################################################
##	Point to the training set and use the column_info list to specify the types of the features.
##########################################################################################################################################
variables_all = [var for var in column_info]
##variables_to_remove = ["eid", "vdate", "discharged", "facid"]
variables_to_remove = ["ClaimClaimID", "ClaimDateClosed", "ClaimReportedDate"]
training_variables = [x for x in variables_all if x not in variables_to_remove]
LoS_Train = RxSqlServerData(sql_query = "SELECT ClaimClaimID, {} FROM LoS WHERE ClaimClaimID IN (SELECT ClaimClaimID from Train_Id)".format(", ".join(training_variables)),
                            connection_string = connection_string,
                            column_info = column_info)

##########################################################################################################################################
##	Specify the variables to keep for the training 
##########################################################################################################################################
##variables_to_remove = ["eid", "vdate", "discharged", "facid", "lengthofstay"]
variables_to_remove = ["ClaimClaimID", "ClaimDateClosed", "ClaimReportedDate", "lengthofstay"]
training_variables = [x for x in variables_all if x not in variables_to_remove]
formula = "lengthofstay ~ " + " + ".join(training_variables)

##########################################################################################################################################
## Training model based on model selection
##########################################################################################################################################
# Parameters of both models have been chosen for illustrative purposes, and can be further optimized.

if model_name == "RF":
	# Train the Random Forest.
	model = rx_dforest(formula=formula,
						data=LoS_Train,
						n_tree=40,
						cp=0.00005,
						min_split=int(sqrt(70000)),
						max_num_bins=int(sqrt(70000)),
						seed=5)
elif model_name == "GBT":
	# Train the Gradient Boosted Trees (rx_btrees implementation).
	model = rx_btrees(formula=formula,
						data=LoS_Train,
						n_tree=40,
						learning_rate=0.3,
						cp=0.00005,
						loss_function="gaussian",
						min_split=int(sqrt(70000)),
						max_num_bins=int(sqrt(70000)),
						seed=9)
elif model_name == "FT":
	# Train the Fast Trees (rx_fast_trees implementation).
	model = rx_fast_trees(formula=formula,
                          data=LoS_Train,
                          num_trees=40,
                          method="regression",
                          learning_rate=0.2,
                          split_fraction=5/24,
                          min_split=10)
else:
	# Train the Neural Network (rx_neural_network implementation).
	model = rx_neural_network(formula=formula,
                            data=LoS_Train,
                            method = "regression",
                            num_hidden_nodes = 128,
                            num_iterations = 100,
                            optimizer = adadelta_optimizer(),
                            mini_batch_size = 20)
			   				       
OutputDataSet = DataFrame({"payload": dill.dumps(model)}, index=[0])'
, @params = N' @model_name varchar(20), @dataset_name varchar(max), @info varbinary(max), @database_name varchar(max)'
, @model_name = @model_name 
, @dataset_name =  @dataset_name
, @info = @info
, @database_name = @database_name

UPDATE Models set model_name = @model_name 
WHERE model_name = 'default model'

;
END
GO
