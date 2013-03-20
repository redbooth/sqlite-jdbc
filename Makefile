# use JDK1.5 to build native libraries

include Makefile.common

RESOURCE_DIR = src/main/resources

.phony: all package win mac linux native deploy

all: package

deploy: 
	mvn deploy 

MVN:=mvn
SRC:=src/main/java
SQLITE_OUT:=$(TARGET)/$(sqlite)-$(OS_NAME)-$(OS_ARCH)
SQLITE_ARCHIVE:=$(TARGET)/$(sqlite)-amal.zip
SQLITE_UNPACKED:=$(TARGET)/sqlite-unpack.log
SQLITE_AMAL_DIR=$(TARGET)/$(SQLITE_AMAL_PREFIX)


CFLAGS:= -I$(SQLITE_OUT) -I$(SQLITE_AMAL_DIR) $(CFLAGS)

$(SQLITE_ARCHIVE):
	@mkdir -p $(@D)
	curl -o$@ http://www.sqlite.org/2013/$(SQLITE_AMAL_PREFIX).zip

$(SQLITE_UNPACKED): $(SQLITE_ARCHIVE)
	unzip -qo $< -d $(TARGET)
	touch $@


$(SQLITE_OUT)/org/sqlite/%.class: src/main/java/org/sqlite/%.java
	@mkdir -p $(@D)
	$(JAVAC) -source 1.5 -target 1.5 -sourcepath $(SRC) -d $(SQLITE_OUT) $<

jni-header: $(SRC)/org/sqlite/NativeDB.h

$(SQLITE_OUT)/NativeDB.h: $(SQLITE_OUT)/org/sqlite/NativeDB.class
	$(JAVAH) -classpath $(SQLITE_OUT) -jni -o $@ org.sqlite.NativeDB

test:
	mvn test

clean: clean-native clean-java clean-tests


$(SQLITE_OUT)/sqlite3.o : $(SQLITE_UNPACKED)
	@mkdir -p $(@D)
	$(CC) -o $@ -c $(CFLAGS) \
	    -DSQLITE_ENABLE_UPDATE_DELETE_LIMIT \
	    -DSQLITE_ENABLE_COLUMN_METADATA \
	    -DSQLITE_CORE \
	    -DSQLITE_THREADSAFE=0 \
	    $(SQLITE_FLAGS) \
	    $(SQLITE_AMAL_DIR)/sqlite3.c

$(SQLITE_OUT)/$(LIBNAME): $(SQLITE_OUT)/sqlite3.o $(SRC)/org/sqlite/NativeDB.c $(SQLITE_OUT)/NativeDB.h
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $(SQLITE_OUT)/NativeDB.o $(SRC)/org/sqlite/NativeDB.c
	$(CC) $(CFLAGS) -o $@ $(SQLITE_OUT)/*.o $(LINKFLAGS)
	$(STRIP) $@

NATIVE_DLL:=$(TARGET)/lib/$(OS_NAME)/$(OS_ARCH)/$(LIBNAME)
NATIVE_TARGET_DIR:=$(TARGET)/classes/org/sqlite/native/$(OS_NAME)/$(OS_ARCH)

native: $(SQLITE_UNPACKED) $(NATIVE_DLL)

$(NATIVE_DLL): $(SQLITE_OUT)/$(LIBNAME)
	@mkdir -p $(@D)
	cp $< $@
	@mkdir -p $(NATIVE_TARGET_DIR)
	cp $< $(NATIVE_TARGET_DIR)/$(LIBNAME)


win32: 
	$(MAKE) native CC=i686-w64-mingw32-gcc OS_NAME=Windows OS_ARCH=x86

linux32:
	$(MAKE) native OS_NAME=Linux OS_ARCH=i386


sparcv9:
	$(MAKE) native OS_NAME=SunOS OS_ARCH=sparcv9


mac32:
	$(MAKE) native OS_NAME=Mac OS_ARCH=i386


package: native
	rm -rf target/dependency-maven-plugin-markers
	$(MVN) package

clean-native:
	rm -rf $(TARGET)/$(sqlite)-$(OS_NAME)*

clean-java:
	rm -rf $(TARGET)/*classes

clean-tests:
	rm -rf $(TARGET)/{surefire*,testdb.jar*}
