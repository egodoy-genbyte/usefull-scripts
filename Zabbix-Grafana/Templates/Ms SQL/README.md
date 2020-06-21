
# Ms SQL Template for Zabbix

This template was designed for:

* Discover all SQL Instances, and corresponding windows service
* Discover all databases (except system DB) and return names and ID
* Query DB Data and Log file size
* Query DB Data and Log free space on files
* Query DB Data and Log file growht conifguration
* Query performance counters related to SQL

## Requeriments in SQL Server

You will need to create a local user with the correct privileges, and update the corresponding macros in template:

* {$USR}: Local SQL user
* {$PWD}: local SQL user password

:closed_lock_with_key: Field type is set to "secret text", so you don't need to be worried about other Zabbix admins can see the credentials

With this parameters set you will be able to discover all DB and query it's sizes.

## Service

The most used conifugration in SQL is to have only one instance and service in the Server. Owever, we can find other situations.

This template will search and register all instances and related services.

:rotating_light: *Triggers an alert when service is stopped*

## How to use this template

It's very simple:

1. Import the template on Zabbix (you must be runnig Zabbix 5)
2. Add sql.conf content to your agent config
3. Copy the PS script (note that you will need to modify sql.conf for your scenario)
4. Create sql users and complete the corresponding macros
5. Enjoy

## :notebook: Next Steps

In nex versions, I would like to incluye:

* More perfomance counter
* Database indivial perfomarnce indicators

# Apendix

## Performance Counters

### Access Methods\Page Splits/sec

> "\SQLServer:Access Methods\Page Splits/sec"

For those not familiar with page splits, let’s first take a look at what they are. Whenever you INSERT new data into a SQL Server table, or in some cases, UPDATE data in a SQL Server table, there may not enough room for the newly INSERTed or UPDATEd row in the applicable data page. In this case, SQL Server will have to move some of the data from the current data page and move it to a new data page. So not only does SQL Server experience the normal I/O of INSERTing or UPDATing a row, it must also move data and update any applicable indexes. This can result in a lot of excess I/O.

Ref: <https://www.sql-server-performance.com/reduce-page-splits/>

### Buffer cache hit ratio

> "\SQLServer:Buffer Manager\Buffer cache hit ratio"

Buffer Cache Hit Ratio shows how SQL Server utilizes buffer cache.
It gives the ratio of the data pages found and read from the SQL Server buffer cache and all data page requests. The pages that are not found in the buffer cache are read from the disk, which is significantly slower and affects performance.
Ideally, SQL Server would read all pages from the buffer cache and there will be no need to read any from disk. In this case, the Buffer Cache Hit Ratio value would be 100. The recommended value for Buffer Cache Hit Ratio is over 90.

:rotating_light: *Triggers an alert when value is below 90*

Ref: <https://www.sqlshack.com/sql-server-memory-performance-metrics-part-4-buffer-cache-hit-ratio-page-life-expectancy/>

### Page life expectancy

> "\SQLServer:Buffer Manager\Page life expectancy"

SQL Server has more chances to find the pages in the buffer pool if they stay there longer. If the page is not in the buffer pool, it will be read from disk, which affects performance. If there’s insufficient memory, data pages are flushed from buffer cache more frequently, to free up the space for the new pages.
When there’s sufficient memory on the server, pages have a high life expectancy. The normal values are above 300 seconds (5 minutes) and the trend line should be stable. It’s recommended to monitor the values over time, as frequent quick drops indicate memory issues. Also, a value drop of more than 50% is a sign for deeper investigation.

Ref: <https://www.sqlshack.com/sql-server-memory-performance-metrics-part-4-buffer-cache-hit-ratio-page-life-expectancy/>

### Processes blocked

> "\SQLServer:General Statistics\Processes blocked"

In any multi-user application you're going to have blocked processes, and SQL Server has mechanisms to handle blocked processes well, but when this counter goes outside the normal range (for your system) you'll want to investigate and see what might be causing the issue. There could be excessive blocking due to page escalation, for example, where entire tables are getting locked instead of individual rows or pages.

### SQL Compilations (and Re-Compilations)

> "\SQLServer:SQL Statistics\SQL Compilations/sec"
>
> "\SQLServer:SQL Statistics\SQL Re-Compilations/sec"

These counters will increment when SQL Server has to compile or recompile query plans because either the plan in cache is no longer valid, or there's no plan in cache for this query. SQL Server uses a cost-based optimizer that relies on statistics to choose a good query plan, and when those statistics are out-of-date, additional compilations are done unnecessarily. It can be useful to understand the source of this problem, if it is a problem (this might be expected behavior, depending on the workload).
