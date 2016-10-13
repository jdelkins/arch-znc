# Docker container for [ZNC][]

## Description

ZNC is an advanced IRC bouncer that is left connected so an IRC client can disconnect/reconnect without losing the chat session.

## Build notes

Latest stable ZNC release from Arch Linux repo.

## Usage

```
docker run -d \
    -p <access port>:6667 \           # <-- if you don't use pipework
    --name=<container name> \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e PUID=<uid for user> \          # <-- default 1000
    -e PGID=<gid for user> \          # <-- default 1000
    -e PIPEWORK_WAIT=yes \            # <-- optional
    jdelkins/arch-znc
```

Please replace all user variables in the above command defined by <> with the correct values.

## Networking

Normally, docker loves to open ports on your host machine and forward them to
your container. This image will work fine in that mode, by simply using an
argument such as `-p 6667:6667`. You can connect to your host at the given
port, by default using http (for webui) or irc.

The alternative (which I usually prefer) is to have the container run on its
own IP address on the LAN, which is bridged through the host's NIC. To do this,
the easiest way I know of is to run it with `--net none` and use the
[pipework][] script to set up networking, as follows:

```
pipework br0 $(docker run -d -e PIPEWORK_WAIT=yes jdelkins/arch-znc)
```

This presumes you have already set up the bridge `br0`, which could be a linux
bridge or an Open vSwitch bridge. See the [pipework][] documentation for more
info.

If you set the environment variable `PIPEWORK_WAIT` as in the example above,
then the container's startup script will wait for pipework to set up the
network interface `eth1` in the container. I have not normally found this
necessary as pipework works very fast, but it's a nice-to-have.

You can specifiy the User ID and Group ID of the running znc process by setting
the `PUID` and `PGID` environment variables respectively using, e.g. `-e
PUID=2000 -e PGID=2000`.  The defaults are `PUID=1000` and `PGID=1000`. It's
perfectly fine to use the defaults of course. On startup, the container will
`chown -R` the entire `/config` directory to be owned by the specified (or
default) user and group, to ensure the znc process can read and write from it's
own configuraiton directory.

## Configuration and setup

On startup, if a configuration file is not found, the image will create
a default one. If you do so, the default username/password combination is
`admin`/`admin`. You can access the web-interface to create your own user by
pointing your web-browser at the opened port.

For example, if you passed in `-p 36667:6667` when running the container, the
web-interface would be available on: `http://hostname:36667/`

I'd recommend you create your own user by cloning the admin user, then ensure
your new cloned user is set to be an admin user. Once you login with your new
user go ahead and delete the default admin user.

See [the ZNC website][ZNC] for more info on setup and configuration.

## External Modules

If you need to use external modules, simply place the original `*.cpp` source
files for the modules in your `{/config}/modules` directory. The startup
script will automatically build all .cpp files in that directory with
`znc-buildmod` every time you start the container.

This ensures that you can easily add new external modules to your znc
configuration without having to worry about building them. And it only slows
down ZNC's startup with a few seconds.

## Passing Custom Arguments to ZNC

This image, by default, runs znc under [supervisord](http://supervisord.org/),
with fixed arguments. This helps to recover the process if it should crash
inside the container. Sometimes, it can be handy to run znc with custom
arguments, and to do so you can override the default arguments as follows. Note
that, in most cases, you should map in a configuration directory using
`-v <some dir>:/config` and tell znc where that directory can be accessed in the
container using `-d /config`. For example:

```
docker run --rm -ti -v $HOME/.znc:/config jdelkins/arch-znc /usr/bin/znc -d /config --makepass
```

This will launch a one-time run of znc with the `--makepass` argument.  Make
note of the use of `-ti` instead of `-d`. This attaches our terminal to
the container, so we can interact with ZNC's makepass process. With `-d` it
would simply run in the background. The `--rm` argument will automatically
remove the spawned container after exection concludes.

[pipework]: https://github.com/jpetazzo/pipework
[ZNC]: http://znc.in
