# grcon

grcon is a lightweight resource virtualization tool for linux processes. grcon is one-binary.


It is an implementation of [rcon](https://github.com/matsumotory/rcon) with golang.

## build

### build

```
make docker
make mod_init
make mod_download
make build
```

## build packages and release

```
make crossbuild
```

## usage
```
 ./grcon --h
Usage of ./grcon:
  -command string
        exec command
  -cpu int
        cpu limit(%) (default 30)
  -group string
        cgroups path (default "grcon")
  -memory int
        memory limit(bytes) (default 536870912)
  -user string
        exec username

## cpu example

#### no limit

- command
```
yes >> /dev/null
```

- cpu usage
```
  PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND
 2591 kunit     20   0 98.6m  616  524 R 99.9  0.1   1:42.42 yes
```

#### limitting cpu 10%

- command
```
sudo ./grcon --user kunit --command "yes >> /dev/null" --cpu 10
```

- cpu usage limitted 10% by grcon
```
  PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND
 2689 kunit     20   0 98.6m  616  524 R 10.0  0.1   0:00.66 yes
```
## References

- https://github.com/matsumotory/rcon
- https://github.com/containerd/cgroups
