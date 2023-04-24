
## How to set up a connection to an SQL database in R; And load an object with geometry (for mapping) from that database
(Last updated: 2023-04-24)  
This is a guide for R users who want to use spatial data from a SQL
server. The main use case is an environment where there is a SQL Server
(in this case, a Microsoft SQL Server) with a database containing
spatial data that you would like to access from R. (SQL Server is
often used to store spatial data for ArcGIS users connect to, so this
is not an unusual scenario.)

Not a comprehensive guide, just the basics. 

### Step 1: connect to the SQL database
The R package you need for this is ```DBI```. It lets you set up a database connection. 

Your R code will look something like this:

```
library(DBI) ## package with commands for connecting to the database
# con will be the database connection R object:
con <- dbConnect(odbc::odbc(),
	Driver="ODBC Driver 18 for SQL Server",
	Server="YOURSERVERNAME",
	Database="YOURDATABASENAME",
	TrustServerCertificate="YES", 
	Trusted_Connection="YES", 
	timeout = 10)
```

#### What are these parameters doing?
* ```Driver``` is the driver used to connect to the database. ```ODBC Driver 17 for SQL Server``` is Microsoft's driver for connecting to Microsoft SQL Server databases. The driver is installed at the system level (not in R). If you administer your own system, you will need to figure out how to install this driver or one that will work for the SQL server you are connecting to.
* ```Server``` and ```Database``` are the names of the database and the machine it lives on. You will need to get these from the administrator of the SQL Server database if you don't already know them.
* ```TrustServerCertificate``` Ideally I think you wouldn't need this option. But if your server certificate doesn't match its name, this lets you get around that. Try it set to ```"NO"``` first, and enable it if you are seeing certificate errors.
* ```Trusted_Connection``` You can use this to tell dbConnect to use Kerberos authentication if that's available on your system. 
	* If you don't have Kerberos, you can replace this parameter with lines like these to send a username and password:
	
	```
	UID = "YOURUSERNAME",
	PWD = rstudioapi::askForPassword("Database password"), ## (assuming you are in Rstudio)
	```

#### For more information
* [https://support.posit.co/hc/en-us/articles/214510788-Setting-up-R-to-connect-to-SQL-Server-](https://support.posit.co/hc/en-us/articles/214510788-Setting-up-R-to-connect-to-SQL-Server-)
* [https://www.r-bloggers.com/2020/09/how-to-connect-r-with-sql/](https://www.r-bloggers.com/2020/09/how-to-connect-r-with-sql/)


### Step 2: select catalog and tables you want to access
Once you have your ```con``` R object connected to the database, you'll
want to start examining the database to find the data you want. The R
package you need to do this is ```odbc```.

Here are the steps:

1. Load the odbc package:  
``` library(odbc) ## package with commands for probing database ```

2. List top-level objects (catalogs) in the database:  
``` odbcListObjects(con) ```

3. Once you know which catalog you want, you will need to know the
schema to access the tables you want from that catalog. This gives you a
list of available schemas for your chosen catalog:  
``` odbcListObjects(con, catalog="YOURCATALOGNAME") ```

4. When you know the schema, you can list the tables in the catalog for that
schema. This command will let you see what tables are available on your
SQL Server:  
``` AVAILABLE_TABLES <- odbcListObjects(con, catalog="YOURCATALOGNAME", schema="YOURSCHEMANAME") ```  
(You don't have to, but at this point you probably want to save the
returned data as an R object like AVAILABLE_TABLES because there might
be many tables and you'll want to pick through them at your leisure.)

5. If you find a table that looks promising, you may want to see what
columns it contains:
``` COL_NAMES_TYPES <- odbcListColumns(con, catalog="YOURCATALOGNAME", schema="YOURSCHEMANAME", table="YOURTABLENAME") ```

6. Optional: Pull out the column names as a list so you can paste them
into your SQL query when you pull your object from the database:
``` COL_NAMES <- COL_NAMES_TYPES[, "name"] ```

At this point, if you don't need geometry data, you can use DBI to bring
data from the table you want into R as a regular data frame:
``` YOUR_DB_OBJECT <- DBI::dbGetQuery(con, paste0("SELECT * FROM ", YOURSCHEMANAME, ".", YOURTABLENAME)) ```  
(The seccond argument of ```dbGetQuery``` lets you pass an arbitrary SQL statement, if you want to compose on the fly.)

#### For more information
* [https://solutions.posit.co/connections/db/r-packages/odbc/](https://solutions.posit.co/connections/db/r-packages/odbc/)


### Step 3: Bring an object into R that has geometry for mapping
If the table you want from your SQL Server includes geometry information 
for mapping, you need one more R package: ```sf```.

* Load the library:  
```library(sf)```
* If you want to list out the columns you want from the table by hand, your code might look something like this:  
``` SHAPE_FROM_SQL <- st_read(con, geometry_column="Shape", query="SELECT YOURCOL1, YOURCOL2, YOURCOL3, YOURCOL4, Shape.STAsBinary() AS Shape FROM YOURSCHEMANAME.YOURTABLENAME") ```  
	* Be sure to check that your geometry column is named "Shape" (its type will be 'geometry') and if not, adjust the Shape.STAsBinary() call in the SQL query.
	* (st_read is supposed to automatically figure out which column has geometry, so you shouldn't need the geometry_column option unless there's two columns with geometry info.)
* Or, if you want to send an R object (named, in this case, COL_NAMES) with a list that contains the column names you want, your code could look like this:  
``` SHAPE_FROM_SQL <- st_read(con, geometry_column="Shape", query="SELECT ", COL_NAMES, ",", Shape.STAsBinary() AS Shape FROM YOURSCHEMANAME.YOURTABLENAME") ```  
	* (COL_NAMES could be what you extracted from odbcListColumns(), or you could edit it yourself, obviously.)
* You can now do a test plot:  
``` plot(SHAPE_FROM_SQL["Shape"], col = "darkgray", border = NA) ```

When you are done, do not forget to disconnect your database connection:  
``` DBI::dbDisconnect(con) # Disconnect from the db ```

#### For more information
* [https://jayrobwilliams.com/posts/2020/09/spatial-sql](https://jayrobwilliams.com/posts/2020/09/spatial-sql)
* If you have huge data, you may need to use a more complex approach:   
[https://hydroecology.net/reading-spatial-data-from-sql-server-without-sf/](https://hydroecology.net/reading-spatial-data-from-sql-server-without-sf/) 




