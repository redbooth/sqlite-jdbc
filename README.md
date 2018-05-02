SQLite JDBC Driver
==================

Forked in 2013 from [sqlite-jdbc](https://bitbucket.org/xerial/sqlite-jdbc) for use in
[AeroFS](https://aerofs.com) desktop client.


## Notable differences from upstream

* Native libraries of SQLite are *not* embedded in the JAR, as this tends to cause weird errors when
  deployed in some environments (typically Windows with aggressive anti-viruses).
* WAL can be used without SHM, for databases that are known to never be shared by multiple processes.
* A few features not useful to our particular use-case are disabled to reduce size and improve speed.


## Build JARs

```
gradle assemble
```

JARs are placed under `build/libs/`


## Build native code

```
make native
```

Native libs are placed under `target/lib/<OS>/<ARCH>/`

*NB* this must be done on each supported platform separately

*TODO* include docker recipes for easy cross-compilation to Linux from Mac/Windows


## Run tests

```
mvn test
```

*TODO* port this to gradle


## Upload to a custom [Nexus repository](https://www.sonatype.com/nexus-repository-sonatype)

Create a `gradle.properties` file from the following template

```
nexusRepo=
nexusUser=
nexusPass=
```

Then run the following gradle tasks:

```
gradle uploadArchives 
```

