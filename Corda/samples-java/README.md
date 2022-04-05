# samples-java

https://github.com/corda/samples-java

The main things are:

1. Use OpenJDK 1.8.0 (this will require a free Red Hat login to download)
2. Use Gradle 5.6.4 ONLY
3. Use git bash on windows

With much thanks to Michael Theriault <michael.s.theriault@gmail.com> who did all the hard work of actually getting this to work and then showed us how to do it. There will also be several documented "gotchas" later on that he also found the hard way.

# Installing Corda samples-java on Windows 10

This will put Corda in C:\Corda and Gradle in C:\Gradle

## Git Bash
https://gitforwindows.org/

Install is simple, download and run installer

Test: run git and bash

```
$ git --version
git version 2.35.1.windows.2
```

```
$ bash --version
GNU bash, version 5.0.17(1)-release (x86_64-pc-linux-gnu)
Copyright (C) 2019 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>

This is free software; you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```

## Java OpenJDK 1.8.0 - Red Hat login required

https://developers.redhat.com/products/openjdk/download

Install the MSI (e.g. jdk-8u322-x64 MSI OpenJDK 8 Windows 64-bit)

Test: 

```
$ java -version
openjdk version "1.8.0_322"
OpenJDK Runtime Environment (build 1.8.0_322-b06)
OpenJDK 64-Bit Server VM (build 25.322-b06, mixed mode)
```

## Gradle install 5.6.4 IMPORTANT (anything other than 5.6.4 and it won't work)

https://docs.gradle.org/current/userguide/installation.html
https://gradle.org/next-steps/?version=5.6.4&format=bin

Install is simple, download the file, make a directory called C:\gradle\, then unpack the gradle file there (creating a new directory called grade-5.6.4-bin that contains the files in gradle-5.6.4) add the gradle bin directory to your path:

```
C:\gradle\gradle-5.6.4-bin\grade-5.6.4\bin
```

This is done by going to computer settings, "View advanced system settings", click on the "Advanced" tab if it isn't already at the front, then click "Environment Variables" at the bottom right. You can set the path for either your user only (top half) or all users (bottom half), either way choose "Path" and click "Edit", in the new screen select "New" and either cut and paste the directory above or use "Browse" to find it. Click "Ok" to save. You do not need to log out/back in for it to take effect.

Test: 

```
$ gradle -v

------------------------------------------------------------
Gradle 5.6.4
------------------------------------------------------------

Build time:   2019-11-01 20:42:00 UTC
Revision:     dd870424f9bd8e195d614dc14bb140f43c22da98

Kotlin:       1.3.41
Groovy:       2.5.4
Ant:          Apache Ant(TM) version 1.9.14 compiled on March 12 2019
JVM:          1.8.0_322 (Red Hat, Inc. 25.322-b06)
OS:           Windows 10 10.0 amd64
```


## Corda samples-java

Install:
run git bash

```
cd /c
mkdir corda
cd corda
git clone https://github.com/corda/samples-java
```
Test: N/A

## Changing Basic/cordaa-example to add 4 more parties

Install:
run git bash
```
cd /c/corda/samples-java/Basic/cordapp-example/
notepad.exe build.gradle
```

Go to the final line and remove the last "}" and then add the following to the file:

https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Corda/samples-java/Basic/cordapp-example/build.gradle-4-more-parties

This defines 4 more parties.

## gradlew build

Install:
run git bash  

```
cd /c/corda/samples-java/Basic/cordapp-example/  
./gradlew.bat deployNodes
```

Test: it should say 11 actionable tasks: 11 executed

## Run the runmodes script:

Install:
run git bash

```
cd /c/corda/samples-java/Basic/cordapp-example/build/nodes/
./runmodes.bat
```

You should see three terminal windows appear with the Corda terminal.


## shutdown the nodes:
```
run gracefulShutdown
```
will put the node into draining mode, and shut down when there are no flows running.

```
run shutdown
```
will shut the node down immediately.

you'll have to run it on each of the three nodes.
