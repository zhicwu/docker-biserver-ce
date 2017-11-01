Use MySQL as Your Repository Database
=====================================

Prerequisites
-------------

* Working docker environment with docker-compose support
* MySQL database server, preferred 5.5 or above


Instructions
------------

1. Create a directory with `docker-compose.yml` and `create-databases.sql`

    ```bash
    $ mkdir pentaho-server
    $ cd pentaho-server
    $ wget https://github.com/zhicwu/docker-biserver-ce/raw/7.1/examples/mysql/docker-compose.yml https://github.com/zhicwu/docker-biserver-ce/raw/7.1/examples/mysql/create-databases.sql
    ```

2. Review and update `docker-compose.yml` as required

    For example, if your server is `biserver.local` and you want to expose port `8080`, you'll need to replace `localhost` to `biserver.local` and `18080` to `8080`:

    ```bash
    $ sed -i -e 's/localhost/biserver.local/' -e 's/18080/8080/' docker-compose.yml
    ```

3. Run and test

    ```bash
    $ docker-compose up
    ```

    Now open up a browser and navigate to http://localhost:18080/pentaho (or http://biserver.local:8080/pentaho in above example), you should be able to use `admin`/`password` to log into the server in a few minutes.

Known Issue
------------

First time starting BI server may fail, when MySQL is not fully initialized **before** BI server started. In case that happened, please shutdown the services and start again.

```
...
<Press Ctrl+C to exit>
$ docker-compose down
$ docker-compose up
...
```

References
----------

* [Official database creation scripts](https://github.com/pentaho/pentaho-platform/tree/7.1.0.5-R/assemblies/pentaho-data/src/main/resources/data/mysql5)
* [Official guide for manual installation](https://help.pentaho.com/Documentation/7.1/Installation/Manual/030_Use_mysql_as_repository_database)