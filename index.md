
## How to set up a connection to an SQL database in R; And load an object with geometry (for mapping) from that database
This is a guide for R users who want to use spatial data from a SQL
server. The main use case is an environment where there is a SQL Server
(in this case, a Microsoft SQL Server) with a database containing
spatial data that you would like to access from R. (A SQL Server is
often used to store spatial data that ArcGIS users connect to, so this
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
* ```Driver``` is the driver used to connect to the database. ```ODBC Driver 17 for SQL Server``` is Microsoft's driver for connecting to Microsoft SQL Server databases. The driver is installed at the system level (not in R). If you manage your own system, you will need to figure out how to install this driver or one that will work for the SQL server you are connecting to.
* ```Server``` and ```Database``` are the names of the database and the machine it lives on. Ask your SQL Server manager if you don't know.
* ```TrustServerCertificate``` Ideally I think you wouldn't need this option. But if your server certificate doesn't match its name, this lets you get around that. Try it without this first, and add it if you are seeing certificate errors.
* ```Trusted_Connection``` You can use this to tell dbConnect to use Kerberos authentication if that's available on your system. 
	* If you don't have Kerberos, you can replace this parameter with lines like these to send a username and password:
	
	```
	UID = "YOURUSERNAME",
	PWD = rstudioapi::askForPassword("Database password"), # (assuming you are in Rstudio),
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

```
library(odbc) ## package with commands for probing database
```

2. List top-level objects (catalogs) in the database:

```
odbcListObjects(con)
```

3. Once you know which catalog you want, you will need to know the
schema to access the tables you want from that catalog. This gives you a
list of available schemas for your chosen catalog:

```
odbcListObjects(con, catalog="YOURCATALOGNAME")
```

4. When you know the schema, you can list the tables in catalog for that
schema. This command will let you see what tables are available on your
SQL server:

```
AVAILABLE_TABLES <- odbcListObjects(con, catalog="YOURCATALOGNAME", schema="YOURSCHEMANAME")
```

(You don't have to, but at this point you probably want to save the
returned data as an R object like AVAILABLE_TABLES because there might
be many tables and you'll want to pick through them at your leisure.)

5. If you find a table that looks promising, you may want to see what columns it contains:

```
COL_NAMES_TYPES <- odbcListColumns(con, catalog="YOURCATALOGNAME", schema="YOURSCHEMANAME", table="YOURTABLENAME")
```

Pull out the column names as a list so you can paste them into your SQL query when you pull your sf object from the database:
col_names <- col_names_types[, "name"]
print(col_names)





