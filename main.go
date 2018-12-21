package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"

	"github.com/containerd/cgroups"
	specs "github.com/opencontainers/runtime-spec/specs-go"
)

func main() {
	var (
		cpu     = flag.Int("cpu", 30, "cpu")
		memory  = flag.Int64("memory", 512*1024*1024, "memory")
		group   = flag.String("group", "grcon", "group")
		user    = flag.String("user", "", "user")
		command = flag.String("command", "", "command")
	)
	flag.Parse()

	if len(*command) == 0 {
		fmt.Println("command not found: --command [command]")
		os.Exit(1)
	}
	if len(*user) == 0 {
		fmt.Println("user not found: --user [username]")
		os.Exit(1)
	}

	path := fmt.Sprintf("/%s", *group)
	quota := int64(*cpu) * 1000
	limit := int64(*memory)
	control, err := cgroups.New(cgroups.V1, cgroups.StaticPath(path), &specs.LinuxResources{
		CPU: &specs.LinuxCPU{
			Quota: &quota,
		},
		Memory: &specs.LinuxMemory{
			Limit: &limit,
		},
	})

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	defer control.Delete()

	if err := control.Add(cgroups.Process{Pid: os.Getpid()}); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	sudoCommand := fmt.Sprintf("sudo -u %s %s", *user, *command)
	cmd := exec.Command("sh", "-c", sudoCommand)
	out, err := cmd.Output()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Print(string(out))
}
