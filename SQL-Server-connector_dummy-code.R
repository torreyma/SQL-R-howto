## SQL-Server-connector-_dummy-code.R
## Last modified: 2023-04-12 15:46


########################################
## First step: connect to the SQL server and database

library(DBI) ## package with commands for connecting to the database

## con will be the database connection.
con <- dbConnect(odbc::odbc(),
	Driver="ODBC Driver 18 for SQL Server",
	Server="YOURSERVERNAME",
	Database="YOURDATABASENAME",
	TrustServerCertificate="YES", ## Need this because SQL server name doesn't match it's certificate
	Trusted_Connection="YES", ## This tells dbConnect to use Kerberos authentication
	timeout = 10)

## With Kerberos, it should automatically authenticate with the SQL server, so there's no reason to include UID or password information in the database connection.

## Disconnect with dbDisconnect(con)



########################################
## Second step: select catalog and tables you want to access

library(odbc) ## packages with commands for probing database

## List top-level objects (catalogs) in db:
odbcListObjects(con)

## This gives you a list of available schemas for your chosed catalog. You need to know the schema to access the tables you want.
odbcListObjects(con, catalog="YOURCATALOGNAME")
## In our case, the schema we want is gisiit

## List tables in catalog for gisiit schema -- this is the command you will use any time you want to see what tables are available on the SQL server.
available_tables <- odbcListObjects(con, catalog="YOURCATALOGNAME", schema="YOURSCHEMANAME")

## After you know what table you want, fill it in for this command to get a data frame with the column names and types:
col_names_types <- odbcListColumns(con, catalog="YOURCATALOGNAME", schema="YOURSCHEMANAME", table="YOURTABLENAME")
print(col_names_types)

## Pull out the column names as a list so you can paste them into your SQL query when you pull your sf object from the database:
col_names <- col_names_types[, "name"]
print(col_names)


########################################
## Third step: pull obect with geometry from SQL with st_read()

library(sf)

## Fill in the table you want to pull from in the SQL query.
## Fill in the column names you want to pull from the table in the SQL query (refer to col_names object)
## Check that the geometry column is named "Shape" and if not adjust the Shape.STAsBinary() call in the SQL query
SHAPE_FROM_SQL <- st_read(con, geometry_column="Shape", query="SELECT YOURCOL1, YOURCOL2, YOURCOL3, YOURCOL4, Shape.STAsBinary() AS Shape FROM YOURSCHEMANAME.YOURTABLENAME")
## st_read is supposed to automatically figure out which column has geometry, so you shouldn't need the geometry_column unless there's two columns with geometry info.


## Plot test, fill in column name:
plot(SHAPE_FROM_SQL["YOURCOLNAMe"], col = sf.colors(5, categorical = TRUE), border = NA)


