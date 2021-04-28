# Corda node explorer

Corda node explorer a GUI app for Linux/Windows/Mac OS that allows you to remotely login to a running Corda instance as a specific Party (e.g. PartyA) and then explore/run trasactions, etc.

With much thanks to Michael Theriault <michael.s.theriault@gmail.com> who did all the hard work of actually getting this to work and then showed us how to do it. There will also be several documented "gotchas" later on that he also found the hard way.

## Download and install

https://github.com/corda/node-explorer/releases

## Connecting

## IP / hostname

## Port

The port you connect to is in the file `build.gradle` in the directory of the cordapp you are using (e.g. `Basic/cordapp-example`), specifically it is in the `task deployNodes` section towards the bottom, look for the node rpcSettings address line:

```
node {
    name "O=PartyA,L=London,C=GB"
    p2pPort 10005
    rpcSettings {
        address("0.0.0.0:10006")
        adminAddress("0.0.0.0:10046")
    }
    rpcUsers = [[ user: "user1", "password": "test", "permissions": ["ALL"]]]
}
node {
    name "O=PartyB,L=New York,C=US"
    p2pPort 10008
    rpcSettings {
        address("0.0.0.0:10009")
        adminAddress("0.0.0.0:10049")
    }
    rpcUsers = [[ user: "user1", "password": "test", "permissions": ["ALL"]]]
}
```

As you can see the default is `10006` for PartyA and `10009` for PartyB.

## Username

The username is `user1` by default (see the above code snippet), you can change this manually before building it if you want to change it.

## Password

The password is `test` by default (see the above code snippet), you can change this manually before building it if you want to change it.

## Setting the path to your Cordapps directory

This is another gotcha that breaks things. You need a copy of the cordapps directory being used on the server(s) locally so the node explorer will work.

You will need to download a copy of the `sample-java` directory locally and then point to it, e.g. `C:\corda\samples-java\Basic\cordapp-example\build\nodes\PartyA\cordapps` please ntoe your MUST include the full path to the cordapps directory including which party you are logging in as.
