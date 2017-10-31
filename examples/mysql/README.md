Use MySQL as Your Repository Database
=====================================

Prerequisites
-------------

* Working docker environment with docker-compose support
* MySQL database server, preferred 5.5 or above


Steps
-----

1. Create databases on MySQL

    Basically you need to:
    * create `hibernate`, `jackrabbit` and `quartz` 3 databases on your MySQL

        ```sql
        CREATE DATABASE IF NOT EXISTS `hibernate` DEFAULT CHARACTER SET latin1;

        CREATE DATABASE IF NOT EXISTS `jackrabbit` DEFAULT CHARACTER SET latin1;

        CREATE DATABASE IF NOT EXISTS `quartz` DEFAULT CHARACTER SET latin1;

        USE `quartz`;

        DROP TABLE IF EXISTS QRTZ5_JOB_LISTENERS;
        DROP TABLE IF EXISTS QRTZ5_TRIGGER_LISTENERS;
        DROP TABLE IF EXISTS QRTZ5_FIRED_TRIGGERS;
        DROP TABLE IF EXISTS QRTZ5_PAUSED_TRIGGER_GRPS;
        DROP TABLE IF EXISTS QRTZ5_SCHEDULER_STATE;
        DROP TABLE IF EXISTS QRTZ5_LOCKS;
        DROP TABLE IF EXISTS QRTZ5_SIMPLE_TRIGGERS;
        DROP TABLE IF EXISTS QRTZ5_CRON_TRIGGERS;
        DROP TABLE IF EXISTS QRTZ5_BLOB_TRIGGERS;
        DROP TABLE IF EXISTS QRTZ5_TRIGGERS;
        DROP TABLE IF EXISTS QRTZ5_JOB_DETAILS;
        DROP TABLE IF EXISTS QRTZ5_CALENDARS;


        CREATE TABLE QRTZ5_JOB_DETAILS
        (
            JOB_NAME  VARCHAR(200) NOT NULL,
            JOB_GROUP VARCHAR(200) NOT NULL,
            DESCRIPTION VARCHAR(250) NULL,
            JOB_CLASS_NAME   VARCHAR(250) NOT NULL,
            IS_DURABLE VARCHAR(1) NOT NULL,
            IS_VOLATILE VARCHAR(1) NOT NULL,
            IS_STATEFUL VARCHAR(1) NOT NULL,
            REQUESTS_RECOVERY VARCHAR(1) NOT NULL,
            JOB_DATA BLOB NULL,
            PRIMARY KEY (JOB_NAME,JOB_GROUP)
        );

        CREATE TABLE QRTZ5_JOB_LISTENERS
        (
            JOB_NAME  VARCHAR(200) NOT NULL,
            JOB_GROUP VARCHAR(200) NOT NULL,
            JOB_LISTENER VARCHAR(200) NOT NULL,
            PRIMARY KEY (JOB_NAME,JOB_GROUP,JOB_LISTENER),
            FOREIGN KEY (JOB_NAME,JOB_GROUP)
                REFERENCES QRTZ5_JOB_DETAILS(JOB_NAME,JOB_GROUP)
        );

        CREATE TABLE QRTZ5_TRIGGERS
        (
            TRIGGER_NAME VARCHAR(200) NOT NULL,
            TRIGGER_GROUP VARCHAR(200) NOT NULL,
            JOB_NAME  VARCHAR(200) NOT NULL,
            JOB_GROUP VARCHAR(200) NOT NULL,
            IS_VOLATILE VARCHAR(1) NOT NULL,
            DESCRIPTION VARCHAR(250) NULL,
            NEXT_FIRE_TIME BIGINT(13) NULL,
            PREV_FIRE_TIME BIGINT(13) NULL,
            PRIORITY INTEGER NULL,
            TRIGGER_STATE VARCHAR(16) NOT NULL,
            TRIGGER_TYPE VARCHAR(8) NOT NULL,
            START_TIME BIGINT(13) NOT NULL,
            END_TIME BIGINT(13) NULL,
            CALENDAR_NAME VARCHAR(200) NULL,
            MISFIRE_INSTR SMALLINT(2) NULL,
            JOB_DATA BLOB NULL,
            PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
            FOREIGN KEY (JOB_NAME,JOB_GROUP)
                REFERENCES QRTZ5_JOB_DETAILS(JOB_NAME,JOB_GROUP)
        );

        CREATE TABLE QRTZ5_SIMPLE_TRIGGERS
        (
            TRIGGER_NAME VARCHAR(200) NOT NULL,
            TRIGGER_GROUP VARCHAR(200) NOT NULL,
            REPEAT_COUNT BIGINT(7) NOT NULL,
            REPEAT_INTERVAL BIGINT(12) NOT NULL,
            TIMES_TRIGGERED BIGINT(10) NOT NULL,
            PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
            FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP)
                REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
        );

        CREATE TABLE QRTZ5_CRON_TRIGGERS
        (
            TRIGGER_NAME VARCHAR(200) NOT NULL,
            TRIGGER_GROUP VARCHAR(200) NOT NULL,
            CRON_EXPRESSION VARCHAR(200) NOT NULL,
            TIME_ZONE_ID VARCHAR(80),
            PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
            FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP)
                REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
        );

        CREATE TABLE QRTZ5_BLOB_TRIGGERS
        (
            TRIGGER_NAME VARCHAR(200) NOT NULL,
            TRIGGER_GROUP VARCHAR(200) NOT NULL,
            BLOB_DATA BLOB NULL,
            PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
            FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP)
                REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
        );

        CREATE TABLE QRTZ5_TRIGGER_LISTENERS
        (
            TRIGGER_NAME  VARCHAR(200) NOT NULL,
            TRIGGER_GROUP VARCHAR(200) NOT NULL,
            TRIGGER_LISTENER VARCHAR(200) NOT NULL,
            PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP,TRIGGER_LISTENER),
            FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP)
                REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
        );


        CREATE TABLE QRTZ5_CALENDARS
        (
            CALENDAR_NAME  VARCHAR(200) NOT NULL,
            CALENDAR BLOB NOT NULL,
            PRIMARY KEY (CALENDAR_NAME)
        );



        CREATE TABLE QRTZ5_PAUSED_TRIGGER_GRPS
        (
            TRIGGER_GROUP  VARCHAR(200) NOT NULL, 
            PRIMARY KEY (TRIGGER_GROUP)
        );

        CREATE TABLE QRTZ5_FIRED_TRIGGERS
        (
            ENTRY_ID VARCHAR(95) NOT NULL,
            TRIGGER_NAME VARCHAR(200) NOT NULL,
            TRIGGER_GROUP VARCHAR(200) NOT NULL,
            IS_VOLATILE VARCHAR(1) NOT NULL,
            INSTANCE_NAME VARCHAR(200) NOT NULL,
            FIRED_TIME BIGINT(13) NOT NULL,
            PRIORITY INTEGER NOT NULL,
            STATE VARCHAR(16) NOT NULL,
            JOB_NAME VARCHAR(200) NULL,
            JOB_GROUP VARCHAR(200) NULL,
            IS_STATEFUL VARCHAR(1) NULL,
            REQUESTS_RECOVERY VARCHAR(1) NULL,
            PRIMARY KEY (ENTRY_ID)
        );

        CREATE TABLE QRTZ5_SCHEDULER_STATE
        (
            INSTANCE_NAME VARCHAR(200) NOT NULL,
            LAST_CHECKIN_TIME BIGINT(13) NOT NULL,
            CHECKIN_INTERVAL BIGINT(13) NOT NULL,
            PRIMARY KEY (INSTANCE_NAME)
        );

        CREATE TABLE QRTZ5_LOCKS
        (
            LOCK_NAME  VARCHAR(40) NOT NULL, 
            PRIMARY KEY (LOCK_NAME)
        );

        INSERT INTO QRTZ5_LOCKS values('TRIGGER_ACCESS');
        INSERT INTO QRTZ5_LOCKS values('JOB_ACCESS');
        INSERT INTO QRTZ5_LOCKS values('CALENDAR_ACCESS');
        INSERT INTO QRTZ5_LOCKS values('STATE_ACCESS');
        INSERT INTO QRTZ5_LOCKS values('MISFIRE_ACCESS');

        commit;
        ```
    * create an account named `pentaho` and grant it full access to above databases

        ```sql
        CREATE USER 'pentaho'@'%' IDENTIFIED BY 'pentaho';

        GRANT ALL ON `hibernate`.* TO 'pentaho'@'%';
        GRANT ALL ON `jackrabbit`.* TO 'pentaho'@'%';
        GRANT ALL ON `quartz`.* TO 'pentaho'@'%';

        FLUSH PRIVILEGES;
        ```
    
    You can create databases on different MySQL servers, and if you want, you can create multiple DB accounts one for accessing each database. However, for simplicity, let's go with one MySQL server and one DB account.

2. Update docker configuration

    Assume your MySQL server is `mysql.local` and it's listening on port `3306`. You want to expose port `18080` on your BI server, say `bi-server.local`, to provide BI service. You'll need a `.env` file with the following content.

        ```ini
        SERVER_HOST=bi-server.local
        SERVER_PORT=18080

        STORAGE_TYPE=mysql5
        DATABASE_TYPE=mysql
        DATABASE_HOST=mysql.local
        DATABASE_PORT=3306
        DATABASE_USER=pentaho
        DATABASE_PASSWD=pentaho
        ```

3. Run and test

    This is the simple part. Follow instructions below, open up a browser and navigate to http://bi-server.local:18080/pentaho, you should be able to use `admin`/`password` log into the server in a few minutes.

        ```bash
        # cd </path/to/docker-compose.yml>
        # docker-compose up
        ...
        <Press Ctrl+C to exit>
        ```
    Also if you take a look at the databases you just created, you'll see a few tables being created during server starting.

References
----------

* [Official database creation scripts](https://github.com/pentaho/pentaho-platform/tree/7.1.0.5-R/assemblies/pentaho-data/src/main/resources/data/mysql5)
* [Official guide for manual installation](https://help.pentaho.com/Documentation/7.1/Installation/Manual/030_Use_mysql_as_repository_database)