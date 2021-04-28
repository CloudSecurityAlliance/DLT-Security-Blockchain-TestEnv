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

Install
Test: run git bash

## Java OpenJDK 1.8.0 - Red Hat login required

https://developers.redhat.com/products/openjdk/download

Install the MSI
Test: ```java -version```

## Gradle install 5.6.4 IMPORTANT (anything other than 5.6.4 and it won't work)

https://docs.gradle.org/current/userguide/installation.html
https://gradle.org/next-steps/?version=5.6.4&format=bin

Instal is simple, download the file, make a directory called C:\gradle\, then unpack the gradle file there (creating a new directory called grade-5.6.4-bin that contains the files in gradle-5.6.4) add the gradle bin directory to your path:

```
C:\gradle\gradle-5.6.4-bin\grade-5.6.4\bin
```

This is done by going to computer settings, "View advanced system settings", click on the "Advanced" tab if it isn't already at the front, then click "Environment Variables" at the bottom right. You can set the path for either your user only (top half) or all users (bottom half), either way choose "Path" and click "Edit", in the new screen select "New" and either cut and paste the direcotry above or use "Browse" to find it. Click "Ok" to save. You do not need to log out/back in for it to take effect.

Test: ```gradle -v```


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

## gradlew build

Install:
run git bash  

```
cd /c/corda/samples-java/CBasic/cordapp-example/  
./gradlew.bat deployNodes
```

Test: it should say 11 actionable tasks: 11 executed

## Run the runmodes script:

Install:
run git bash

```
cd /c/corda/samples-java/CBasic/cordapp-example/build/nodes/
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
